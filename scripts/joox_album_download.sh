#!/usr/bin/env bash
set -euo pipefail

ALBUM_ID="${1:?Usage: $0 ALBUM_ID [ROOT_DIR]}"
ROOT_DIR="${2:-${JOOX_ROOT_DIR:-/tmp/joox-downloads}}"
UA="${JOOX_UA:-Mozilla/5.0}"
COOKIE="${JOOX_COOKIE:-wmid=142420656; user_type=1; country=id; session_key=2a5d97d05dc8fe238150184eaf3519ad;}"
XFF="${JOOX_XFF:-36.73.34.109}"
JOOX_LANG="${JOOX_LANG:-zh_TW}"
JOOX_COUNTRY="${JOOX_COUNTRY:-hk}"

curl_common_args=( -H "user-agent: ${UA}" )
[ -n "$COOKIE" ] && curl_common_args+=( -H "cookie: ${COOKIE}" )
[ -n "$XFF" ] && curl_common_args+=( -H "x-forwarded-for: ${XFF}" )

sanitize() {
  printf '%s' "$1" | sed 's#[/\\:*?"<>|]#_#g; s/[[:space:]]\+$//'
}

joox_get() {
  curl -fsSL "$@" "${curl_common_args[@]}"
}

extract_next_data() {
  perl -0777 -ne 'print $1 if /<script id="__NEXT_DATA__" type="application\/json" crossorigin="anonymous">(.*?)<\/script>/s'
}

album_json="$(joox_get "https://www.joox.com/hk/album/${ALBUM_ID}" | extract_next_data)"
album_name="$(printf '%s' "$album_json" | jq -r '.props.pageProps.albumData.title')"
artist_name="$(printf '%s' "$album_json" | jq -r '.props.pageProps.albumData.artistList[0].name')"

album_dir="${ROOT_DIR}/$(sanitize "$artist_name")/$(sanitize "$album_name")"
mkdir -p "$album_dir"

printf '%s' "$album_json" | jq -c '.props.pageProps.albumTrackData.tracks.items[]' | while IFS= read -r track; do
  song_id="$(printf '%s' "$track" | jq -r '.id')"
  song_name="$(printf '%s' "$track" | jq -r '.name')"
  safe_song="$(sanitize "$song_name")"

  echo "START\t${album_name}\t${song_name}"

  info=''
  for i in 1 2 3 4; do
    raw="$(curl -fsSG 'https://api.joox.com/web-fcgi-bin/web_get_songinfo' \
      --data-urlencode "songid=${song_id}" \
      --data-urlencode "lang=${JOOX_LANG}" \
      --data-urlencode "country=${JOOX_COUNTRY}" \
      "${curl_common_args[@]}" || true)"
    info="$(printf '%s' "$raw" | perl -0777 -pe 's/^\s*MusicInfoCallback\((.*)\)\s*$/\1/s')"
    if printf '%s' "$info" | jq -e . >/dev/null 2>&1; then
      break
    fi
    sleep 2
  done

  url="$(printf '%s' "$info" | jq -r '
    .master_tapeUrl // .master_tapeURL // .hiresUrl // .hiresURL // .flacUrl // .flacURL // .r320Url // .r320url // .r192Url // .r192url // .mp3Url // .m4aUrl // empty
  ')"

  if [ -z "$url" ]; then
    echo "FAIL_NO_URL\t${song_name}"
    continue
  fi

  ext="${url%%\?*}"
  ext="${ext##*.}"
  [ -n "$ext" ] || ext='mp3'
  out="${album_dir}/${safe_song}.${ext}"

  if [ ! -s "$out" ]; then
    if curl -fsSL --retry 4 --retry-delay 2 --connect-timeout 15 --max-time 240 \
      "${curl_common_args[@]}" \
      -o "$out" "$url"; then
      echo "DONE_AUDIO\t${song_name}\t${out}"
    else
      rm -f "$out"
      echo "FAIL_AUDIO\t${song_name}"
      continue
    fi
  else
    echo "SKIP_AUDIO_EXISTS\t${song_name}\t${out}"
  fi

  lrc="${album_dir}/${safe_song}.lrc"
  if [ ! -s "$lrc" ]; then
    lyric_raw="$(curl -fsSG 'https://api.joox.com/web-fcgi-bin/web_lyric' \
      --data-urlencode "musicid=${song_id}" \
      --data-urlencode "country=${JOOX_COUNTRY}" \
      --data-urlencode "lang=${JOOX_LANG}" \
      "${curl_common_args[@]}" || true)"
    lyric_json="$(printf '%s' "$lyric_raw" | perl -0777 -pe 's/^\s*MusicJsonCallback\((.*)\)\s*$/\1/s')"
    lyric_b64="$(printf '%s' "$lyric_json" | jq -r '.lyric // empty' 2>/dev/null || true)"
    if [ -n "$lyric_b64" ]; then
      printf '%s' "$lyric_b64" | base64 -d > "$lrc" 2>/dev/null || rm -f "$lrc"
    fi
    [ -s "$lrc" ] && echo "DONE_LRC\t${song_name}\t${lrc}" || echo "NO_LRC\t${song_name}"
  fi

done

echo "DONE_ALBUM\t${artist_name}\t${album_name}\t${album_dir}"

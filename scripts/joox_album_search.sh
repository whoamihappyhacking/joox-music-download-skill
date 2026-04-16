#!/usr/bin/env bash
set -euo pipefail

KEYWORD="${1:?Usage: $0 KEYWORD [LIMIT]}"
LIMIT="${2:-10}"
UA="${JOOX_UA:-Mozilla/5.0}"
COOKIE="${JOOX_COOKIE:-wmid=142420656; user_type=1; country=id; session_key=2a5d97d05dc8fe238150184eaf3519ad;}"
XFF="${JOOX_XFF:-36.73.34.109}"
JOOX_LANG="${JOOX_LANG:-zh_TW}"
JOOX_COUNTRY="${JOOX_COUNTRY:-hk}"

curl_common_args=( -H "user-agent: ${UA}" )
[ -n "$COOKIE" ] && curl_common_args+=( -H "cookie: ${COOKIE}" )
[ -n "$XFF" ] && curl_common_args+=( -H "x-forwarded-for: ${XFF}" )

curl -fsSG 'https://cache.api.joox.com/openjoox/v2/search_type' \
  --data-urlencode "country=${JOOX_COUNTRY}" \
  --data-urlencode "lang=${JOOX_LANG}" \
  --data-urlencode "key=${KEYWORD}" \
  --data-urlencode 'type=1' \
  "${curl_common_args[@]}" \
| jq -r --argjson limit "$LIMIT" '
    .albums[0:$limit][]
    | [(.name // ""), (.publish_date // ""), (.id // "")]
    | @tsv
  '

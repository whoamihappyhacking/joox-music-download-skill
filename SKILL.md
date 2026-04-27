---
name: joox-music-download
description: 使用经过实测的 curl+jq+bash 工作流下载 JOOX 专辑音频与歌词，避免写死本地常量，改为通过环境变量注入，并采用安全的本地默认目录与已验证的 JSONP 解析方式。
version: 1.2.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [joox, music, download, bash, curl, jq, lyrics, album]
---

# JOOX 音乐下载

适用场景：
- 用户明确希望通过 JOOX 下载歌曲或专辑
- 可以接受 shell 脚本工作流
- 需要一个已经实测跑通、适合发布给外部复用的方案

重要原则：
- 注意版权与平台规则
- 不要默认写入用户网盘路径，除非用户明确同意
- 优先先写到临时目录或本地目录做验证

## 懒猫网盘 / 本机默认存放约定
如果这是在当前这台带懒猫网盘的机器上使用，应额外遵循下面约定：

- 当前机器上的懒猫网盘文稿数据根目录默认是：`/config/Desktop/文稿数据`
- 音乐默认存放目录是：`/config/Desktop/文稿数据/Music`
- 音乐文件应按下面结构整理：

```text
/config/Desktop/文稿数据/Music/<歌手名>/<专辑名>/<歌曲名>.<ext>
/config/Desktop/文稿数据/Music/<歌手名>/<专辑名>/<歌曲名>.lrc
```

示例：

```text
/config/Desktop/文稿数据/Music/G.E.M. 鄧紫棋/喜歡你/喜歡你.mp3
/config/Desktop/文稿数据/Music/G.E.M. 鄧紫棋/喜歡你/喜歡你.lrc
```

如果当前环境不是这台机器，或者用户没有说明自己的懒猫网盘目录在哪里：
- 不要擅自假定网盘路径一定存在
- 应先询问用户其懒猫网盘 / 文稿数据目录位置
- 在未确认前，先使用临时目录或本地目录进行验证

## 已验证内容
这个工作流已经通过多个单曲专辑做过端到端验证。

已观测到的成功结果：
- 周杰倫《Mojito》成功下载音频与 `.lrc`，耗时约 37 秒
- G.E.M. 鄧紫棋《喜歡你》成功下载音频与 `.lrc` 到 `/tmp/joox-dengziqi-test/G.E.M. 鄧紫棋/喜歡你/`
- 下载得到的 `喜歡你.mp3` 非空（观测值 `9562876` bytes）
- 下载得到的 `喜歡你.lrc` 非空（观测值 `1404` bytes），且带有效时间轴歌词头
- 通用脚本名 `joox_album_download.sh` 与搜索辅助脚本 `joox_album_search.sh` 已完成实测
- 旧脚本名 `lazycat_joox_album_download.sh` 现作为兼容入口，内部转发到新脚本

示例验证输出路径：
- `/tmp/joox-test/周杰倫/Mojito/Mojito.mp3`
- `/tmp/joox-test/周杰倫/Mojito/Mojito.lrc`
- `/tmp/joox-dengziqi-test/G.E.M. 鄧紫棋/喜歡你/喜歡你.mp3`
- `/tmp/joox-dengziqi-test/G.E.M. 鄧紫棋/喜歡你/喜歡你.lrc`

## 脚本路径
这个 skill 自带以下脚本，打包时应与 `SKILL.md` 一起放在同一个 skill 目录中：

```text
scripts/joox_album_download.sh
scripts/joox_album_search.sh
```

如果在 Hermes skill 目录中查看，它们的实际路径是：
```text
/config/.hermes/skills/media/joox-music-download/scripts/joox_album_download.sh
/config/.hermes/skills/media/joox-music-download/scripts/joox_album_search.sh
```

如果把这个 skill 单独下载/打包出去，保持 `SKILL.md` 与 `scripts/` 目录同级即可，命令示例里的相对路径可以直接使用。

## 发布 / 打包要求
- 这个 skill 必须按“自包含目录”发布：`SKILL.md` 与 `scripts/` 一起分发
- 不要把主逻辑只放在 `/config/.hermes/scripts` 再让 skill 文档去引用外部绝对路径；那样不利于下载、打包和跨机器复用
- 对外文档优先使用相对路径示例：`bash scripts/joox_album_search.sh ...`、`bash scripts/joox_album_download.sh ...`
- 与当前机器绑定的信息（例如懒猫网盘默认目录 `/config/Desktop/文稿数据/Music`）应作为“本机约定 / 可选默认值”写入，而不是写成所有环境都成立的硬编码前提

## 安全默认行为
脚本默认应写入临时本地目录，而不是用户网盘：
```bash
ROOT_DIR="${2:-${JOOX_ROOT_DIR:-/tmp/joox-downloads}}"
```

脚本默认内置一组当前用户要求保留的 JOOX 请求头，同时仍允许用环境变量覆盖：
```bash
JOOX_ROOT_DIR   # 省略第 2 个参数时的默认输出目录
JOOX_UA         # HTTP User-Agent，默认 Mozilla/5.0
JOOX_COOKIE     # 可覆盖默认内置 JOOX cookie
JOOX_XFF        # 可覆盖默认内置 x-forwarded-for IP
JOOX_LANG       # 默认 zh_TW
JOOX_COUNTRY    # 默认 hk
```

重要澄清：
- 按当前用户明确要求，skill 脚本保留内置 cookie / x-forwarded-for 默认值；如需切换，再用环境变量覆盖
- 在真实环境里，专辑搜索有时匿名也能返回部分结果，但音频下载与歌词接口经常仍然需要有效 cookie / 登录态 / 区域条件
- 因此如果要把这个 skill 发布给外部用户，必须先审查这组内置值是否仍应随 skill 一起分发；不能误表述成“匿名开箱即用”

如果用户希望写到别的目录，显式传第 2 个参数即可。

如果用户明确同意写入当前机器的懒猫网盘音乐目录，可直接传：

```bash
/config/Desktop/文稿数据/Music
```

## 用法
按 JOOX album ID 下载专辑：
```bash
bash scripts/joox_album_download.sh <ALBUM_ID> [ROOT_DIR]
```

示例：
```bash
export JOOX_COOKIE='your_cookie_here'
export JOOX_XFF='your_ip_here'
bash scripts/joox_album_download.sh 'gVeZBi8ielgZmW9ORUwO5Q==' /tmp/joox-dengziqi-test
```

写入当前机器懒猫网盘 Music 目录的示例：

```bash
export JOOX_COOKIE='your_cookie_here'
export JOOX_XFF='your_ip_here'
bash scripts/joox_album_download.sh 'gVeZBi8ielgZmW9ORUwO5Q==' '/config/Desktop/文稿数据/Music'
```

如果用户给的是歌手名或专辑名，而不是精确 album ID，应先搜索再下载：
```bash
export JOOX_COOKIE='your_cookie_here'
export JOOX_XFF='your_ip_here'
export JOOX_LANG='zh_TW'
export JOOX_COUNTRY='hk'

bash scripts/joox_album_search.sh '邓紫棋' 10
```

把候选结果列给用户选择。不要静默下载第一个结果。

如果用户要求“全部下载专辑”，应先做一层去重与筛选：
- 排除明显不是专辑主体的条目，例如：`EP`、`Remix`、单曲、Soundtrack、Interlude 类条目
- 同一专辑若出现多个版本，优先保留更完整或更贴近用户偏好的版本
- 若用户明确说“优先 Explicit”，则重复版本中优先保留带 `Explicit` 标记的版本
- 若同时存在普通版与 `Expanded Edition (Explicit)`，优先保留后者
- 去重后再批量下载，避免把同名专辑下出多份

## 输出目录结构
文件写入结构：
```text
ROOT_DIR/<artist>/<album>/<song>.<ext>
ROOT_DIR/<artist>/<album>/<song>.lrc
```

在当前机器的懒猫网盘场景下，推荐固定理解为：

```text
/config/Desktop/文稿数据/Music/<歌手名>/<专辑名>/<歌曲名>.<ext>
/config/Desktop/文稿数据/Music/<歌手名>/<专辑名>/<歌曲名>.lrc
```

## 工作原理
下载脚本 `joox_album_download.sh` 的流程：
1. 访问 `https://www.joox.com/hk/album/<ALBUM_ID>` 获取专辑页 HTML
2. 从页面中提取 `__NEXT_DATA__` JSON
3. 用 `jq` 读取专辑元数据与曲目列表
4. 对每首歌依次执行：
   - 调 `web_get_songinfo`
   - 去掉 JSONP wrapper
   - 用 `jq` 解析 JSON
   - 从高音质字段到 MP3/M4A 字段依次挑选可用音频 URL
   - 下载音频文件
   - 调 `web_lyric`
   - 将 base64 歌词解码为 `.lrc`

搜索脚本 `joox_album_search.sh` 的流程：
1. 调 JOOX `search_type` 接口
2. 根据关键词搜索专辑（`type=1`）
3. 输出 `专辑名<TAB>发行日期<TAB>album_id`
4. 将候选结果展示给用户后，再决定是否下载

## 关键解析修复
JOOX 的 `web_get_songinfo` 可能返回多行 JSONP，不能用天真的单行剥壳方式处理。

应使用这个已经实测的解析方式：
```bash
info="$(printf '%s' "$raw" | perl -0777 -pe 's/^\s*MusicInfoCallback\((.*)\)\s*$/\1/s')"
```

歌词接口也应使用对应写法：
```bash
lyric_json="$(printf '%s' "$lyric_raw" | perl -0777 -pe 's/^\s*MusicJsonCallback\((.*)\)\s*$/\1/s')"
```

除非重新用真实返回值验证通过，否则不要改回按行处理的 `sed` 剥壳方式。

## 推荐的 curl 行为
脚本里推荐使用 quiet/fail/follow：
```bash
curl -fsSL
```

下载音频时建议保留重试与超时控制：
```bash
curl -fsSL --retry 4 --retry-delay 2 --connect-timeout 15 --max-time 240 -o "$out" "$url"
```

## 依赖要求
需要这些命令：
- `bash`
- `curl`
- `jq`
- `perl`
- `base64`

真实环境里通常还需要这些运行时输入：
- 在匿名请求不够用的环境里，通常需要有效的 `JOOX_COOKIE`
- 如果部署环境需要地域提示，可选提供 `JOOX_XFF`
- 如需控制区域/语言，可选提供 `JOOX_LANG` 与 `JOOX_COUNTRY`

## 验证清单
下载完成后，至少检查：
1. 专辑目录存在
2. 音频文件存在且非空
3. 若有歌词，歌词文件存在
4. 脚本输出最后包含 `DONE_ALBUM`

快速验证示例：
```bash
find /tmp/joox-test -type f | sort
```

## 常见坑
- 有些歌曲可能拿不到可用下载 URL
- 有些歌曲可能没有歌词
- 多行 JSONP 必须用支持多行的方式剥壳
- 未经用户明确同意，不要默认写入 `/config/Desktop/文稿数据`
- 当前机器上的懒猫网盘音乐目录约定为 `/config/Desktop/文稿数据/Music`
- 如果用户明确要求写入懒猫网盘音乐目录，按 `歌手/专辑/歌曲` 层级保存
- 如果用户没有明确说明自己的懒猫网盘目录位置，不要假定别的机器也一定是 `/config/Desktop/文稿数据`
- 批量下载英文歌手时，JOOX 搜索结果里常会混入 `Remix`、`EP`、单曲、Soundtrack 等非目标条目，不能简单按“全部结果”原样下载
- 同一专辑可能出现普通版、Explicit 版、Expanded Edition 等多个变体；若用户有偏好，应先做版本去重与优选
- 如果某个旧脚本“明明没配置环境变量却还能下载”，先检查脚本里是否残留硬编码的 `COOKIE=` / `XFF=`；不要把这种历史残留误判为 JOOX 可匿名下载
- 追查历史来源时，优先检查上游 `musicdl` 的 `JooxMusicClient` 源码；已现场验证过，某些 `musicdl` 版本的 `modules/sources/joox.py` 会在 `default_search_headers` / `default_parse_headers` 中直接内置示例性的 `cookie` 与 `x-forwarded-for`。如果你发现旧脚本里的值与这些默认头一致，应优先判断为“从上游包抄过来的历史常量”，而不是当前环境自动登录所得
- 实测上，匿名请求通常可做部分搜索，歌词接口有时也可返回；但 `web_get_songinfo` 往往会报 `code=-20050` / `msg=invaid cookie`，拿不到 `mp3Url` / `m4aUrl` 等关键字段，因此当前下载链路不能默认宣传为“免 Cookie 可用”
- 当 JOOX 专辑页匿名打开被重定向到 `/intl`、`__NEXT_DATA__` 里拿不到曲目时，先退回歌曲级搜索（例如用元数据搜索接口先定位 `song_id`、歌手、专辑），不要误以为该曲库里完全没有这首歌

## 适用时机
- 用户明确要求使用 JOOX 下载
- 需要一个已经验证过的 shell 工作流，而不是未验证的 Python 包方案
- 需要确定性的本地输出路径与日志
- 需要一个适合对外发布、避免懒猫/LazyCat 私有命名的通用脚本方案
- 需要在当前机器上把音乐落到懒猫网盘 `Music/歌手/专辑/歌曲` 结构中

## 不适用时机
- 用户只要搜索结果或元数据，不需要实际下载
- 用户只是要一个合法可重分发的测试音频样本；这种情况优先用 `samplelib-music-download`
- 用户没有同意读写网盘，而目标路径又在 `/config/Desktop/文稿数据` 下

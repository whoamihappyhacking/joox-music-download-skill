# JOOX Music Download Skill

这是一个给 Hermes / 懒猫微服环境使用的 JOOX 音乐下载 skill。它通过 `bash + curl + jq + perl` 工作流，先搜索 JOOX 专辑，再按专辑下载音频和歌词，适合在本机或懒猫网盘目录中整理音乐资料。

## 目录结构

```text
.
├── README.md
├── SKILL.md
└── scripts
    ├── joox_album_download.sh
    └── joox_album_search.sh
```

## 这个 Skill 能做什么

- 按关键词搜索 JOOX 专辑
- 按 `album_id` 下载整张专辑
- 自动解析音频地址并下载歌曲文件
- 自动尝试拉取并保存 `.lrc` 歌词
- 按歌手 / 专辑整理目录结构，便于放入懒猫网盘管理

## 使用前准备

需要系统具备以下命令：

- `bash`
- `curl`
- `jq`
- `perl`
- `base64`

在很多环境里，JOOX 接口还需要有效请求头，常见方式是通过环境变量提供：

```bash
export JOOX_COOKIE='your_cookie_here'
export JOOX_XFF='your_ip_here'
export JOOX_LANG='zh_TW'
export JOOX_COUNTRY='hk'
```

如果不传输出目录，脚本默认写到：

```text
/tmp/joox-downloads
```

如果你是在懒猫微服机器上运行，并且希望直接写入懒猫网盘音乐目录，可以改为：

```text
/config/Desktop/文稿数据/Music
```

## 如何使用

### 1. 搜索专辑

先通过关键词搜索专辑，拿到目标 `album_id`：

```bash
bash scripts/joox_album_search.sh '邓紫棋' 10
```

输出格式为：

```text
专辑名    发行日期    album_id
```

建议先人工确认结果，不要默认直接下载第一条。

### 2. 下载专辑

确认 `album_id` 后执行：

```bash
bash scripts/joox_album_download.sh <ALBUM_ID> [ROOT_DIR]
```

示例：

```bash
export JOOX_COOKIE='your_cookie_here'
export JOOX_XFF='your_ip_here'
bash scripts/joox_album_download.sh 'gVeZBi8ielgZmW9ORUwO5Q==' /tmp/joox-test
```

写入懒猫网盘的示例：

```bash
export JOOX_COOKIE='your_cookie_here'
export JOOX_XFF='your_ip_here'
bash scripts/joox_album_download.sh 'gVeZBi8ielgZmW9ORUwO5Q==' '/config/Desktop/文稿数据/Music'
```

## 输出结构

下载后的文件会整理成下面这种结构：

```text
ROOT_DIR/<歌手名>/<专辑名>/<歌曲名>.<ext>
ROOT_DIR/<歌手名>/<专辑名>/<歌曲名>.lrc
```

例如：

```text
/config/Desktop/文稿数据/Music/G.E.M. 鄧紫棋/喜歡你/喜歡你.mp3
/config/Desktop/文稿数据/Music/G.E.M. 鄧紫棋/喜歡你/喜歡你.lrc
```

## 在 Skill 中的典型使用方式

如果你把这个项目作为 skill 放进 Hermes 或懒猫微服的 skill 目录，通常按下面流程使用：

1. 让助手先搜索专辑。
2. 从候选列表中选中正确的 `album_id`。
3. 再执行下载脚本，把专辑保存到本地目录或懒猫网盘目录。

建议把 `SKILL.md` 和 `scripts/` 一起分发，不要只拷贝脚本文件。

## 注意事项

- 请自行确认版权、平台规则和使用场景是否合规。
- JOOX 接口行为可能受登录态、地区和请求头影响。
- 对外发布前，应重新审查脚本中的默认请求参数是否适合继续保留。
- 初次使用建议先下载到 `/tmp` 验证，再决定是否写入正式网盘目录。

## 什么是懒猫微服

从产品定位上看，懒猫微服不只是一个传统 NAS，更强调“私有云中心”。它的核心思路是把存储、数据管理、本地服务、AI 能力和日常协作能力整合到一台本地设备中。

结合现有资料，懒猫微服的主要特点包括：

- 不只是文件存储，还强调私有云、本地服务和数据掌控
- 基于 `LightOS`，降低 Linux 和私有云使用门槛
- 支持本地部署、容器化扩展、远程访问和多场景数据管理
- 面向生活家、内容创作者、技术爱好者和开发者
- 支持将照片、资料、影音、聊天数据和 AI 工具统一放在自己的设备里

如果你希望把音乐、歌词、聊天资料和 AI 工作流放到自己的私有环境里，懒猫微服就是这个 skill 比较适合的运行平台。

## 小龙猫介绍

小龙猫是懒猫微服团队开发的新一代 AI Agent 管理软件，支持 OpenClaw、Hermes 等 AI Agent，也支持微信、飞书、钉钉等 IM 工具，整体目标是把 AI Agent 的安装、配置、运行和管理做成真正开箱即用。

它的核心特点包括：

- 只需输入 AI Key，安装、配置和启动全自动完成，不用配置 JSON，不用折腾网关，开箱即可聊天
- 内置 OpenClaw 和 Hermes 等先进 AI Agent，兼容官方协议，并增强支持图片显示、文件下载、附件上传、网页预览和语音聊天
- 支持 Claude、GPT、Gemini 和多种国内 AI 中转站，大幅降低 AI 使用成本，更省 Token、更省钱
- 内置微信、飞书和钉钉支持，创建 AI 助手后扫码绑定，即可接入日常办公聊天场景
- 内置版本升级和版本管理，升级异常可一键回滚旧版本，省心升级不怕数据受影响
- 支持记忆导出和导入，提前备份到懒猫网盘后，可在新助手中恢复旧助手记忆和聊天记录
- 基于 `LightOS` 独立操作系统构建，每个助手运行在独立隔离的文件系统中，数据更安全，运行更稳定
- 内置图形化桌面环境和 Linux 软件仓库，AI Agent 可使用浏览器、GUI 工具和 Linux 软件包，自主开发更多工具
- 支持 AI Agent 群聊，让不同助手搭配不同模型协同工作，助力一人公司高效成长
- 支持网盘文件权限控制，可配置全盘读写、全盘只读、全盘只写和自定义路径权限，提升效率同时保护核心数据
- 配合懒猫 AI 算力舱支持语音聊天，可直接用语音向 AI Agent 下达任务
- AI 供应商支持 API Key 和 OAuth 登录、创建编辑删除、自动检测，并可为不同助手独立分配模型
- 为开发者内置 `LightOS` 终端、AI 诊断机器人和图形桌面等调试工具，方便实验 AI Agent 社区技巧
- 充分拥抱 Skill 和 MCP 生态，未来将接入 `LightOS`、懒猫应用、商店应用和懒猫 AI 算力舱等资源
- 相比云端 AI Agent 工具，小龙猫更隐私、更安全、更方便、更省钱

## 这个 Skill 和懒猫微服 / 小龙猫的关系

这个 JOOX 下载 skill 很适合放在懒猫微服和小龙猫生态里使用：

- 懒猫微服提供本地私有云、网盘和稳定运行环境
- 小龙猫提供 AI Agent 管理、IM 接入和更低门槛的操作体验
- 这个 skill 则负责完成一个具体任务：搜索并下载 JOOX 专辑与歌词，然后落盘到本地或懒猫网盘

组合起来，比较适合做成“聊天指令触发下载、自动整理进网盘”的落地场景。

## 购机优惠咨询

如果你准备购买懒猫微服机器，可以直接添加微信咨询并领取优惠券。

- 微信号入口：`懒猫微服技术特点-购机优惠咨询`
- 咨询目的：购机咨询、领取优惠券
- 直接扫码添加下面这个微信
- 添加后请备注来意，方便快速对接

可直接备注：

```text
想购买懒猫微服机器，领取优惠券
```

![购机优惠咨询二维码](qrcode.jpg)

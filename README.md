# Nightelf 工作台

本地优先的 macOS AI 资源工作台。提示词、SKILL、MCP、网站链接与 Workflow 都落在你自己的 Vault 目录里——文件即真相，不依赖云端账号。

## Quickstart

需要本机已安装 [Flutter](https://docs.flutter.dev/get-started/install)（macOS desktop 已启用）。

```bash
flutter pub get
flutter run -d macos
```

或用仓库脚本构建并打开 Debug 包：

```bash
./script/build_and_run.sh
```

首次启动选择「创建 Vault」或「打开 Vault」。之后会记住上次目录（含 macOS security-scoped bookmark），冷启动直接回到工作台。

## How it works

打开应用后，它不会急着把你丢进空白编辑器。你先选定一个 Vault——本地文件夹里放着 `.ai-vault.json` 与分类目录。侧栏按类型浏览资源，点开后在中间编辑，右侧可看元数据与操作。

提示词与 MCP 是 Markdown / JSON 文件；SKILL 是文件夹；网站链接可内嵌浏览，也能在桌面挂一颗 flat 悬浮球一键外开；Workflow 支持源码与画布。改动写回磁盘，同步与最近打开都围着这份 Vault 转。

## What's inside

- **Vault** — 本地资源库，创建时带 Nightelf 文件夹图标，启动自动恢复上次打开的库
- **AI 提示词** — Markdown 提示词，复制纯文本 / Markdown、副本与回收站
- **SKILL 文件夹** — 浏览与编辑 skill 目录，Finder / 终端快捷入口
- **MCP 配置** — JSON 编辑、格式化与安全模板
- **网站链接** — 内置浏览器 + 桌面悬浮球
- **Workflow** — Mermaid 源码与画布
- **概览** — 进入 Vault 后的总览与拖放入口

Dart 包名仍为 `ai_workbench`；用户可见品牌为 **Nightelf 工作台**。

## Philosophy

- **本地优先** — 数据在你的磁盘上，路径你说了算
- **文件即真相** — 用普通文件与文件夹协作，而不是私有数据库锁死内容
- **少云依赖** — 核心路径不要求登录或远程同步服务
- **可验证** — 行为用测试锁住，尤其是导航与 Vault 恢复这类「静默失败」点

## Development

```bash
flutter test
flutter build macos --debug
```

面向 macOS；App Sandbox 下通过 security-scoped bookmark 保持对用户所选 Vault 的访问。

## License

详见仓库许可证文件（若尚未添加，以项目所有者声明为准）。

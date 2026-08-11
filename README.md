<p align="center">
  <img src="assets/nightelf-logo.png" width="104" alt="Nightelf logo">
</p>

<h1 align="center">Nightelf 工作台</h1>

<p align="center">
  <strong>本地优先的 macOS AI 资源工作台：把 Prompt · Skill · MCP · Link · Workflow 收进自己的 Vault，文件即真相。</strong><br>
  A local-first macOS workbench for the AI assets you want to keep portable, inspectable, and yours.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS-111827?logo=apple&logoColor=white" alt="macOS">
  <img src="https://img.shields.io/badge/built%20with-Flutter-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/data-local--first-1F6F50" alt="Local-first">
</p>

<p align="center">
  <a href="docs/images/nightelf-workbench.png"><img src="docs/images/nightelf-workbench.png" alt="Nightelf workbench showing the Vault sidebar, workspace, and metadata inspector"></a>
</p>

<p align="center">如果 Nightelf 适合你的工作流，欢迎给仓库点一颗 Star。</p>

## Why Nightelf / 为什么是 Nightelf

Prompt、SKILL、MCP 配置、常用 AI 网站和 Workflow 很容易散落在聊天记录、下载目录和不同工具之间。Nightelf 用一个本地 Vault 把它们放回可浏览、可编辑、可迁移的文件结构中：你可以继续用 Finder、编辑器和 Git 处理自己的资产，而不是把核心内容锁进某个云端账号。

**In short:** Nightelf makes a local folder your AI asset library, so the files stay understandable and portable beyond the app.

> Nightelf 管理资源，不运行 MCP server，也不是内置 LLM 聊天客户端。

## Capabilities / 功能

- **Vault** — 创建或打开本地资源库；下次启动会恢复上次打开的 Vault，并在 macOS 上保留对用户选择目录的 security-scoped bookmark 访问。
- **Prompt** — 以 Markdown 保存提示词，支持创建、编辑、复制与回收站恢复。
- **Skill** — 导入含根级 `SKILL.md` 的文件夹，在应用中浏览和编辑文件，并提供 Finder / 终端入口。
- **MCP** — 保存和编辑 JSON 配置，提供 JSON 语法诊断与格式化；配置只作为文件管理，不会由 Nightelf 执行。
- **网站链接** — 保存链接资料，在内置浏览器中打开 HTTP(S) 页面，或通过 macOS 桌面悬浮球快速在外部打开。
- **Workflow** — 保存与编辑工作流文档，可在 Mermaid 源码与画布视图之间工作；Nightelf 不执行工作流。
- **概览、搜索与元数据** — 从 Vault 总览进入资源，按标题、标签和可搜索文本查找；收藏、合集、描述、标签、关联资源与最近打开项随 Vault 保存。
- **macOS 使用路径** — 原生目录选择、上次 Vault 恢复、Finder / 终端快捷入口，以及网页悬浮球都围绕桌面文件工作流设计。

## Quick Start / 快速开始

需要在 **macOS** 上安装 Flutter SDK，并启用 Flutter macOS desktop 支持；Nightelf 不随仓库附带 Flutter，也不声明支持其他桌面或移动平台。

```bash
flutter pub get
flutter run -d macos
```

也可以用仓库脚本构建 Debug 包并打开应用：

```bash
./script/build_and_run.sh
```

首次启动时，选择「创建 Vault」或「打开 Vault」。创建会把所选文件夹作为资源库根目录；打开时选择包含 `.ai-vault.json` 的 Vault 根目录（即使先选中其下的资源子目录，应用也会定位回根目录）。

## Your Vault on Disk / 磁盘上的 Vault

Vault 是普通文件夹：资源文件可以被 Finder、编辑器和 Git 直接访问。当前应用创建并使用以下结构：

```text
my-nightelf-vault/
├── .ai-vault.json          # Vault 标识与版本
├── prompts/                # Markdown Prompt
├── skills/                 # SKILL 文件夹
├── mcp/                    # MCP JSON 配置
├── links/                  # 网站链接记录
├── workflows/              # Workflow 文档
└── .ai-workbench/          # 应用管理的收藏、合集、资源元数据、本地状态和画布布局
```

`.ai-workbench/` 是当前实现使用的应用管理状态目录；其 `local/` 内容会由 Vault 自带的 `.gitignore` 排除。资源本身仍保存在上方的类型目录中，因此可以按自己的工具和版本控制习惯继续维护。

## Status / 当前状态

Nightelf 正在持续开发中。打包的 **Releases / DMG 下载：Coming soon**；目前请使用上面的 macOS 源码构建方式。

## Development / 开发

```bash
flutter test
flutter build macos --debug
```

## Contributing / 参与贡献

欢迎通过 [Issues](../../issues) 反馈问题、提出想法或讨论使用场景；也欢迎提交 [Pull Requests](../../pulls)，一起完善这个本地优先的 macOS 工作台。

## License / 许可证

项目许可证尚未发布；在仓库提供许可证文件之前，请先联系项目维护者确认使用与分发方式。

---

喜欢这种把 AI 资产留在自己手里的工作方式？欢迎 Star 支持 Nightelf。

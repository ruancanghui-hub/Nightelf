## Why

AI 工作流需要的提示词、SKILL、MCP 配置、工作流文件和常用网站分散在各处，切换成本高且难复用。需要一个类 Obsidian 的本地优先 Mac 桌面应用，用统一库（Vault）收藏、编写与组织这些资源，让个人/小团队能像管理笔记一样管理 AI 资产。

## What Changes

- 新建 Flutter macOS 桌面应用，提供类 Obsidian 的侧边栏 + 内容区布局
- 引入本地 Vault：以文件夹为根，资源以文件/目录形式落盘，可被外部编辑器与 Git 管理
- 支持收藏夹/集合，对任意资源类型打星、分组
- 支持编写与管理 AI 提示词（Markdown/纯文本）
- 支持导入、浏览与管理 SKILL 文件夹
- 支持保存与编辑 MCP 配置（如 JSON）
- 支持收藏网站链接（标题、URL、备注、标签）
- 支持存放与编辑 workflow 文件
- 提供基础搜索（按名称、标签、内容片段）与按类型筛选
- **首期范围假设（可调整）**：仅 macOS；本地优先，不做云同步；不做多用户协作；不做内嵌大模型对话（本应用是资源库，不是聊天客户端）

## Capabilities

### New Capabilities
- `desktop-shell`: Flutter macOS 应用壳、窗口与类 Obsidian 导航布局
- `vault-workspace`: 本地 Vault 打开/创建、目录树、收藏/集合、搜索与筛选
- `prompt-library`: AI 提示词的创建、编辑、标签与收藏
- `skill-library`: SKILL 文件夹的导入、浏览、打开与元数据管理
- `mcp-library`: MCP 配置的新建、编辑、校验与收藏
- `link-library`: 网站链接的收藏、打开与备注
- `workflow-library`: workflow 文件的导入、编辑与组织

### Modified Capabilities
- （无；仓库为新建项目，尚无既有 specs）

## Impact

- 新建 Flutter macOS 工程与依赖（桌面窗口、文件系统、Markdown 编辑等）
- 新增 Vault 目录约定与各资源类型的文件 schema
- 影响后续产品范围：同步、插件、跨平台（Windows/Linux）不在本变更内
- 与 Cursor/Claude 等外部工具的衔接通过文件兼容实现，不内嵌其运行时

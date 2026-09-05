# 只有启动器可以调起外部进程

Nightelf 的产品边界是管理与编辑 Vault 资源，不执行 Prompt、SKILL、MCP 或 Workflow。启动器是窄例外：点击「启动」时把 `.command` / `.sh` 交给 macOS（`open` 或 Terminal），应用自己不内嵌运行、不跟踪进程。这样做是为了在工作台里集中打开各项目的一键脚本，同时避免把 Nightelf 做成通用脚本运行器。

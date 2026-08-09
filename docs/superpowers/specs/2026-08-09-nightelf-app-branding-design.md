# Nightelf 应用品牌化设计

## 目标

将已确认的 Nightelf 五叶标志统一用于 macOS App Icon、应用启动闪屏和 Vault 欢迎页，同时保持已接入的工作台侧栏 Logo 不变。

## 品牌资产

- 界面内继续使用透明背景的 `assets/nightelf-logo.png`。
- App Icon 使用独立的 1024 像素主图：深黑绿圆角方形底，中央为翡翠绿 Nightelf 标志。
- App Icon 不使用洋红背景，不包含文字、水印或额外图形。
- 标志保持完整五叶轮廓，四周保留安全边距，在 16 像素下仍能辨认。

## macOS App Icon

- 替换 `macos/Runner/Assets.xcassets/AppIcon.appiconset` 中的全部现有 Flutter 默认图标。
- 从同一个 1024 像素主图生成 `16`、`32`、`64`、`128`、`256`、`512` 和 `1024` 像素 PNG。
- 保持现有 `Contents.json` 文件名与 macOS 1x/2x 映射不变。
- Finder、Dock 和应用窗口引用同一套图标资产。

## 启动闪屏

- 应用每次冷启动时先显示 Nightelf 品牌闪屏。
- 闪屏使用深黑绿背景，居中显示透明 Nightelf Logo，不显示按钮或其他内容。
- Logo 以 `128 × 128` 显示，进行短暂淡入淡出。
- 闪屏总时长为 `900 ms`，结束后自动进入当前 Vault 状态对应页面。
- 闪屏不执行网络请求、Vault 读写或额外持久化。

## Vault 欢迎页

- 将当前 `_WelcomeScaffold` 中的 Lucide 通用叶片图标替换为透明 Nightelf Logo。
- Logo 以 `96 × 96` 显示，居中位于标题上方。
- 保留现有深黑绿卡片、文案、“创建 Vault”、“打开 Vault”和错误提示。
- 不改变目录选择、Vault 恢复或失败处理逻辑。

## 状态与交互

1. 应用启动时显示闪屏。
2. `900 ms` 后隐藏闪屏。
3. 若 Vault 已恢复，显示工作台；若未打开 Vault，显示品牌欢迎页；若恢复失败，欢迎页继续显示原有错误信息。
4. 用户不需要点击或跳过闪屏。

## 测试与验收

- 小组件测试确认应用初始显示闪屏，定时结束后显示正确 Vault 页面。
- 欢迎页测试确认 Logo 资产、显示尺寸以及两个 Vault 操作按钮存在。
- 图标资产检查确认七个 PNG 尺寸正确、都为正方形，且 `Contents.json` 引用文件完整。
- macOS Debug 构建成功，重新启动后可依次看到闪屏与欢迎页/工作台。
- Dock 中不再显示 Flutter 默认图标。

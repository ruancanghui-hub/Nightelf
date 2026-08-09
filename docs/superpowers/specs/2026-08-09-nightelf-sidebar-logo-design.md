# Nightelf 侧栏 Logo 替换设计

## 目标

将工作台左侧栏顶部现有的 Lucide 通用叶片图标替换为用户参考图中的 Nightelf 三叶标志，提高品牌识别度并保持参考图一致性。

## 范围

- 仅替换左侧栏顶部、`Nightelf · AI 工作台` 文字左侧的 Logo。
- Logo 在界面中的显示尺寸保持 `34 × 34`。
- 保持现有文字、侧栏宽度、顶部间距、导航布局和交互不变。
- 不修改 macOS 应用图标、Dock 图标或其他页面图标。

## 资产方案

- 以用户提供的参考图为视觉依据，生成轮廓一致的绿色三叶 Nightelf 标志。
- 输出透明背景 PNG，项目路径为 `assets/nightelf-logo.png`。
- 资产采用足够高的像素密度，确保在 Retina 屏幕以 `34 × 34` 显示时边缘清晰。
- 不保留截图背景，不使用文字、阴影、水印或额外装饰。

## 代码接入

- 在 `pubspec.yaml` 的现有资产配置中注册 Logo。
- 在 `WorkbenchSidebar` 品牌区使用 `Image.asset` 替换 `LucideIcons.leafyGreen`。
- 图片使用 `BoxFit.contain`，宽高固定为 34，避免改变品牌行布局。

## 验收标准

- 左侧栏只显示新的三叶 Logo，不再显示通用叶片图标。
- Logo 背景透明，边缘无明显色边或深色矩形。
- 位置、尺寸和文字基线与替换前一致。
- 侧栏与概览布局测试通过，macOS Debug 构建成功。

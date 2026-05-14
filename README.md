# Smart Display Switcher Enhanced / 智能显示器切换助手 增强版

Automated Desktop Environment Optimizer

---

## 简介 / What It Does

自动检测显示器配置并智能切换桌面布局：
- 小屏幕（笔记本）：隐藏桌面图标 + 启动 EasyDesktop
- 大屏幕（外接显示器）：显示桌面图标 + 停止 EasyDesktop
- 多屏幕（双屏）：显示桌面图标 + 停止 EasyDesktop

Detects your monitor setup and automatically switches desktop layout:
- Small screen (laptop): hides desktop icons, starts EasyDesktop
- Large screen (external monitor): shows desktop icons, stops EasyDesktop
- Two or more screens: dual mode (shows icons, stops EasyDesktop)

## 快速开始 / Quick Start

1. 编辑 `config.json` — 设置 EasyDesktop 路径
2. 以管理员身份运行 `install.bat` — 添加开机自启任务
3. 双击 `Start-Switcher.bat` — 启动系统托盘

1. Edit `config.json` — set your EasyDesktop path
2. Run `install.bat` as Administrator — adds startup task
3. Double-click `Start-Switcher.bat` — launches system tray icon

## 项目结构 / Project Structure

```
SmartDisplaySwitcher-Enhanced/
├── modules/          Monitor, DesktopControl, ProcessManager,
│                    ConfigManager, I18n, Logger
├── lang/             zh-CN.json, en-US.json
├── assets/           tray.ico
├── SmartDisplaySwitcher.ps1   主程序（系统托盘）/ Main script (system tray)
├── Start-Switcher.bat         启动器 / Launcher
├── install.bat                安装 / Installer
├── uninstall.bat              卸载 / Uninstaller
└── config.json                配置文件
```

## 配置 / Configuration

```json
{
  "primaryMonitor": { "minPhysicalWidth": 24 },
  "apps": [
    { "name": "EasyDesktop", "path": "D:/EasyDesktop/easyDesktop.exe", "enabled": true }
  ],
  "monitoring": { "checkInterval": 10 },
  "display": { "language": "zh-CN", "showNotifications": true },
  "diagnostics": { "enableFallback": true }
}
```

## 系统要求 / Requirements

- Windows 10/11
- PowerShell 5.1+
- Administrator rights (for install/uninstall) / 管理员权限（安装/卸载时）

## 开源协议 / License

MIT

## 作者 / Author

Ersiter

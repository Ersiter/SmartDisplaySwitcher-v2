<p align="center">
  <img src="assets/tray.ico" width="64" height="64" alt="icon">
</p>

<h1 align="center">Smart Display Switcher v2</h1>
<p align="center"><em>连接显示器，剩下的交给它</em></p>

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-blue" alt="PowerShell">
  <img src="https://img.shields.io/badge/platform-Windows%2010%2F11-lightgrey" alt="platform">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="license">
</p>

---

## ✨ 它能做什么

| 场景 | 自动操作 |
|------|---------|
| 拔掉外接显示器，回到笔记本小屏 | 隐藏桌面图标，启动 EasyDesktop |
| 插上外接大屏 | 显示桌面图标，关闭 EasyDesktop |
| 多屏幕同时用 | 显示桌面图标，关闭 EasyDesktop |

**全程零操作**——插拔屏幕那一瞬间它已经帮你切好了。任务栏托盘常驻，双击图标也能手动切。

### 🧠 巧思

- **双重显示器检测**：优先读 EDID 物理尺寸，不灵时回退到 GDI 毫米数方案——**不受 Windows 150% 缩放干扰**，27 寸就是 27 寸
- **管理员权限自动申请**：不用担心右键"以管理员身份运行"，双击就提权
- **单实例锁**：不小心开了两个？第二个自动退出
- **控制台窗口自动隐藏**：启动后窗口消失，只留托盘图标——干净
- **配置每日自动备份**：改坏了随时回滚，保留最近 30 天

---

## 🚀 安装

### 从 Release 下载（推荐）

等作者上传 release 包，解压即用。

### 从源码安装

```bash
git clone https://github.com/Ersiter/SmartDisplaySwitcher-v2.git
cd SmartDisplaySwitcher-v2
```

然后：

**第一步**——编辑 `config.json`，填上你的 EasyDesktop 路径：
```json
"apps": [
  { "name": "EasyDesktop", "path": "D:/你的路径/easyDesktop.exe", "enabled": true }
]
```

**第二步**——双击 `install.bat`，自动提权 → 验证文件 → 创建开机自启任务 → 可选桌面快捷方式。

**第三步**——双击 `Start-Switcher.bat`（或等下次开机），系统栏出现切换图标。

卸载就双击 `uninstall.bat`。

---

## 📁 项目结构

```
├── modules/          Monitor / DesktopControl / ProcessManager
│                    ConfigManager / I18n / Logger
├── lang/             zh-CN.json  ·  en-US.json
├── assets/           tray.ico
├── SmartDisplaySwitcher.ps1   主程序
├── install.bat      一键安装
├── uninstall.bat    一键卸载
└── config.json      配置文件
```

---

## ⚙️ 配置参考

```json
{
  "primaryMonitor": { "minPhysicalWidth": 24 },
  "apps": [{ "name": "EasyDesktop", "path": "", "enabled": true }],
  "monitoring": { "checkInterval": 10 },
  "display": { "language": "zh-CN", "showNotifications": true },
  "wallpaper": { "enabled": false },
  "diagnostics": { "enableFallback": true }
}
```

| 参数 | 默认 | 说明 |
|------|------|------|
| `minPhysicalWidth` | 24 | 笔记本/桌面分界线（英寸） |
| `language` | zh-CN | 也支持 en-US |
| `checkInterval` | 10 | 检测间隔（秒） |
| `enableFallback` | true | 回退检测方案，关掉只走 WMI |

---

## 📄 License

MIT · Author [Ersiter](https://github.com/Ersiter)

---

## English

Smart Display Switcher detects your monitor setup and switches desktop layout automatically. Plug in an external monitor → icons appear, EasyDesktop stops. Unplug → icons hide, EasyDesktop starts. It lives in your system tray and requires zero interaction.

### Features

- Dual detection: WMI (EDID) + GDI fallback — immune to Windows DPI scaling
- Auto admin elevation — no right-click required
- Single-instance guard
- Console window auto-hides after launch
- Daily config backup, 30-day retention
- Bilingual zh-CN / en-US

### Install

```bash
git clone https://github.com/Ersiter/SmartDisplaySwitcher-v2.git
```

1. Edit `config.json` — set your EasyDesktop path
2. Double-click `install.bat` — auto-elevates, verifies files, creates startup task
3. Double-click `Start-Switcher.bat` — tray icon appears

Uninstall with `uninstall.bat`.

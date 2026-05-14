<p align="center">
  <img src="assets/tray.ico" width="72" height="72">
</p>

<h1 align="center">Smart Display Switcher v2</h1>
<p align="center">
  <em>插拔屏幕那一瞬间，它已经帮你切好了。</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-5391FE?logo=powershell" alt="PowerShell">
  <img src="https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows" alt="Windows">
  <img src="https://img.shields.io/badge/license-MIT-brightgreen" alt="MIT">
</p>

---

## 🤔 你是不是也这样

笔记本外接了个大屏写代码 / 打游戏 / 看电影——爽。一拔线回到小屏，桌面图标挤成一团，EasyDesktop 还开着占资源。每次插拔都要手动关掉 ED、右键隐藏图标，一天折腾八百次。

**烦不烦？**

这个工具就干一件事：盯着你的显示器，**插拔那一瞬间自动切好**。你该干嘛干嘛，不用管它。

---

## ✨ 干了什么

| 场景 | 自动操作 |
|------|---------|
| 笔记本小屏单干 | 🖥️ 隐藏桌面图标 → 启动 EasyDesktop |
| 外接大屏 | 📺 显示桌面图标 → 关闭 EasyDesktop |
| 双屏 / 多屏 | 🖥️📺 显示图标 + 关闭 ED |

全程系统托盘常驻，**双击图标也能手动切**。

### 🧠 几个有意思的地方

- **不受 Windows 缩放干扰**：150% 缩放下很多工具把 27 寸读成 30.6 ——这个读 EDID 物理毫米数，27 就是 27
- **管理员权限不麻烦你**：双击 `.bat` 自己提权，不用右键"以管理员身份运行"
- **防手滑**：不小心开了第二个？自己退出。单实例锁
- **控制台自动隐身**：启动后窗口消失，只剩托盘图标
- **配置每天自动备份**：改坏了就回滚，保留最近 30 天

---

## 🙏 一个项目的前身

如果不是 [Vincent轩](https://gitee.com/codevicent) 的 [EasyDesktop](https://gitee.com/codevicent/easy-desktop)，就不会有这个工具。

他用 C++ 写了一个轻量的桌面增强器：隐藏图标、快速呼出文件面板、毛玻璃主题、零配置上手——这件事本身就帅。我做的只是在外面加了一层"插拔显示器自动开关它"的壳。

内核是他的，自动化是我的。感谢 Vincent 的开源。

---

## 🚀 怎么用

### 1. 下载

```bash
git clone https://github.com/Ersiter/SmartDisplaySwitcher-v2.git
cd SmartDisplaySwitcher-v2
```

### 2. 配置

打开 `config.json`，填你的 EasyDesktop 路径：

```json
"apps": [
  {
    "name": "EasyDesktop",
    "path": "D:/你的EasyDesktop路径/easyDesktop.exe",
    "enabled": true
  }
]
```

### 3. 安装

双击 `install.bat` → 自动提权 → 验证文件 → 创建开机自启任务 → 完事。

（中间会问你要不要桌面快捷方式——要不要都行。）

### 4. 启动

双击 `Start-Switcher.bat`，系统栏出现切换图标。下次开机自动跑。

卸载？双击 `uninstall.bat`。

---

## 📁 里面啥样

```
SmartDisplaySwitcher-v2/
├── modules/
│   ├── Monitor.psm1          # 显示器检测（WMI + GDI 回退）
│   ├── DesktopControl.psm1   # 桌面图标开关
│   ├── ProcessManager.psm1   # EasyDesktop 启动/停止
│   ├── ConfigManager.psm1    # 配置读写 + 自动备份
│   ├── I18n.psm1             # 中英双语
│   └── Logger.psm1           # 日志系统
├── lang/
│   ├── zh-CN.json
│   └── en-US.json
├── assets/
│   └── tray.ico              # 托盘图标
├── SmartDisplaySwitcher.ps1  # 主程序
├── install.bat               # 一键安装
├── uninstall.bat             # 一键卸载
├── Start-Switcher.bat        # 启动脚本
├── config.json               # 配置文件
└── README.md
```

---

## ⚙️ 配置项

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

| 参数 | 默认 | 干啥的 |
|------|------|--------|
| `minPhysicalWidth` | 24 | 多少英寸算"大屏" |
| `checkInterval` | 10 | 几秒扫一次显示器 |
| `language` | zh-CN | 也支持 `en-US` |
| `enableFallback` | true | 双重检测，关了只走 WMI |
| `showNotifications` | true | 切换时托盘弹气泡 |

---

## 📄 License

MIT · [Ersiter](https://github.com/Ersiter)

---

## English

### The problem

You dock your laptop to a big monitor. Work, game, whatever — it's great. Then you unplug. Suddenly your desktop icons are a cluttered mess, EasyDesktop is still chewing resources, and you're manually hiding icons and killing processes. Every. Single. Time.

### What this does

Smart Display Switcher watches your monitor setup and reacts instantly:

| Mode | Trigger | Action |
|------|---------|--------|
| 🖥️ Laptop | Small screen only | Hide desktop icons + start EasyDesktop |
| 📺 Desktop | Large external monitor | Show icons + stop EasyDesktop |
| 🖥️📺 Dual | 2+ monitors | Show icons + stop EasyDesktop |

It lives in your system tray. Double-click to force-switch anytime.

### Cool details

- **Immune to Windows scaling**: Reads physical EDID dimensions in millimeters. No more "27 inch monitor detected as 30.6" because you're at 150% scaling.
- **Auto admin elevation**: Just double-click the `.bat`. No right-click shenanigans.
- **Single-instance guard**: Launched it twice by accident? The second one bows out.
- **Console auto-hide**: The window vanishes after launch. Only the tray icon remains.
- **Daily config backups**: Screwed up your config? Roll back. 30-day retention.

### Quick start

```bash
git clone https://github.com/Ersiter/SmartDisplaySwitcher-v2.git
cd SmartDisplaySwitcher-v2
```

1. Edit `config.json` — point to your EasyDesktop binary
2. Double-click `install.bat` — elevates, verifies, schedules startup
3. Double-click `Start-Switcher.bat` — tray icon appears

Uninstall with `uninstall.bat`.

### Project layout

```
SmartDisplaySwitcher-v2/
├── modules/
│   ├── Monitor.psm1          # EDID + GDI fallback detection
│   ├── DesktopControl.psm1   # Icon visibility via registry
│   ├── ProcessManager.psm1   # App lifecycle management
│   ├── ConfigManager.psm1    # JSON config + auto-backup
│   ├── I18n.psm1             # zh-CN / en-US runtime switch
│   └── Logger.psm1           # Leveled logging with rotation
├── lang/                     # Language packs
├── assets/                   # tray.ico
├── SmartDisplaySwitcher.ps1  # Entry point
├── install.bat               # One-click installer
├── uninstall.bat             # One-click remover
├── Start-Switcher.bat        # Launcher
└── config.json               # User config
```

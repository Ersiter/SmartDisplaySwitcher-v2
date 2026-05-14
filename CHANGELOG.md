# Changelog

## v2.1.0 (2026-05-15)

### Added
- Modular PowerShell architecture (6 independent .psm1 modules)
- System tray icon with custom .ico (multi-resolution: 16/32/48/256px)
- Bilingual support: zh-CN / en-US with runtime switch
- EDID-based monitor physical size detection via WMI + GDI fallback
- Single-instance mutex guard
- Console window auto-hide after launch
- Daily config auto-backup with 30-day retention
- Desktop shortcut option in installer
- Proper version tagging

### Changed
- Author: Ersiter
- Refactored from single .ps1 into 6-module structure
- Batch launchers rewritten as pure ASCII (no encoding issues on Chinese Windows)
- Config schema extended: multi-app support, wallpaper switching, display preferences

### Fixed
- Monitor size miscalculation at 150% Windows scaling (switched to EDID mm reads)
- Explorer restart no longer kills tray icon unnecessarily
- CMD popup loop caused by UTF-8 Chinese in batch files
- `Write-Error` naming conflict with PowerShell built-in
- Scheduled task creation quoting issues with `schtasks /tr`

### Credits
- Inspired by [EasyDesktop](https://gitee.com/codevicent/easy-desktop) by [Vicent轩](https://gitee.com/codevicent)

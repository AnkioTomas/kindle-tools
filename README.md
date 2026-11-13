# Ankio Kindle Tools

作者：Ankio

书库里只会看到一个入口：**Ankio工具箱**。其余文件都在 `/mnt/us/ankio-tools/`，不会作为图书出现。

<img src="preview.png" alt="预览" width="360">

## 功能

- **KOReader 启动**：从菜单启动 KOReader，可选保留或不保留原生框架
- **状态与诊断**：生成可读的状态报告和诊断信息，方便排查问题
- **自动更新开关**：禁用 / 恢复系统自动更新（OTA）
- **KOReader 自启动**：开机自动进入 KOReader，可随时关闭
- **清理锁屏广告**：清除特价版（Special Offers）机型的锁屏广告缓存并阻止再次下载，可恢复
- **Telnet**：临时开启 / 关闭 Telnet，用于调试
- 书库里只有一个入口，所有功能在分组中文菜单里，每次操作后屏幕都有结果提示

## 适用版本

- 设备：已越狱、能从 `documents` 运行 `.sh` 脚本的 Kindle；启动器为 `kindlehf`（ARM 硬浮点）构建，适用于使用 hf 固件的较新机型（大致为 Paperwhite 4 / 10 代及之后）。更老的 soft-float 机型不适用。
- 已实测：Paperwhite 12 / 固件 5.20.2.0.1。其他机型和固件未测试。
- 禁用/恢复自动更新、KOReader 自启动需要 `mntroot`，verity/rootless 设备会被脚本拒绝；Telnet 需要 root、`telnetd`、`iptables`；KOReader 相关菜单要求 `/mnt/us/koreader/koreader.sh` 已存在（本包不含 KOReader）。

## 目录结构

- `documents/Ankio_Toolbox.sh` — 书库里的入口
- `ankio-tools/` — 菜单（`menu.json`、`config.xml`、`KUAL.cfg`）、功能脚本、`koreader_autostart_worker.sh`
  - `kual-next/` — 菜单启动器 [KUAL Next](https://github.com/thiagokokada/kual-next) 0.3.0（kindlehf）及字体、许可证，来源见 `SOURCE.txt`
  - `icons/` — 脚本图标

## 安装（MTP）

解压后，把 `documents`、`ankio-tools` 复制到 Kindle 存储根目录（与已有 documents 同级）并合并。不要把整个 `Ankio-Kindle-Tools` 文件夹放进 documents。不要再把官方 `KUAL Next.sh` 拷进 documents。本包不会删除你设备上的已有文件；若书库里还留着以前那些单独的 `.sh`，可自行移走。首次打开时入口会把字体复制到 `/mnt/us/kual-next/fonts/`（二进制写死了该路径）。弹出后等图书馆刷新，点「Ankio工具箱」。

## 菜单（中文，分组）

- KOReader — 启动：官方 `koreader.sh --kual`（保留原生框架）；启动（不保留原生框架）：`--kual --framework_stop`
- 状态与诊断 — 状态与日志报告写到 `/mnt/us/kindle-diagnostics/status-latest.txt`（MTP 可看），同时写入 KUAL 日志 `/var/tmp/kual-next.log`；在菜单底部 KUAL 项选 Save and reset KUAL log 可存成书库里的 `KUAL-*.txt`。另有运行诊断
- 自动更新 — 禁用 / 恢复
- KOReader 自启动 — 开启 / 关闭
- 锁屏广告 — 清理 / 恢复
- Telnet — 启动 / 停止

KOReader 启动：不重装。若 `koreader.sh` 不存在则不启动；若已在运行则不重复启动。菜单用 exitmenu 只登记白名单动作，等官方 `launch.sh` 完成框架恢复后再启动，避免和 KUAL Next 抢框架导致白屏。未在本机 PW12 / 5.20.2.0.1 实测。

菜单为中文：包内的 `NotoSans.ttf` 已换成 Noto Sans CJK SC 的裁剪版（TrueType 轮廓，仅含 ASCII 和菜单用字，约 80KB）；启动器无字体回退，菜单不使用符号图标。以后改菜单文字需重新裁剪字体（见 `SOURCE.txt`）。启动器自带 Sort / Save and reset KUAL log / Quit。

## 执行反馈

每个动作结束后，屏幕底部会停留约 6 秒的结果框（[ DONE ] / [ FAILED ] 加英文说明，因 eips 无法显示汉字），完整中文结果写入 `/mnt/us/ankio-tools/last-result.txt`。

## 锁屏广告

清理方式：把 `/mnt/us/system/.assets`（广告缓存）清空，并换成同名的空文件，系统就无法再往里写广告；恢复则删除这个空文件。操作后请重启。只对带广告的特价版机型有效，且不保证所有固件都能彻底去除，未在实机验证。

## Telnet 与更新

Telnet 默认不启用。只建议在可信网络临时使用（无密码、不加密、root）。关闭不保证已建立会话断开。禁用自动更新后请先检查有无已下载包，再手动重启；不能永久阻断。KOReader 自启动安装后请手动重启；白屏时可在存储根目录新建 `DISABLE_KOREADER_AUTOSTART`。

## 打包与发布

本地打包：`./package.sh [输出目录]`，默认输出到 `~/Downloads`。

发布：把 `ankio-tools/config.xml` 里的版本号改好并提交后，打同版本的标签并推送（如版本 `2.0` 对应 `v2.0`），GitHub Actions 会自动打包并创建 Release，附上 zip。标签与版本号不一致时会失败。

## 授权

本项目以 [MIT 协议](LICENSE) 发布。随包的第三方组件（KUAL Next、FBInk、jsmn、yxml、Noto 字体）遵循各自许可证，见 `ankio-tools/kual-next/LICENSES/`。

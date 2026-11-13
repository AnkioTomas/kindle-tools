# Ankio Kindle Tools

作者：Ankio

书库里只会看到一个入口：**Ankio工具箱**。所有文件都集中在 `documents/` 下：入口 `Ankio_Toolbox.sh`，其余全部在 `documents/ankio-tools/`。

![预览](preview.png)

## 目录结构

- `documents/Ankio_Toolbox.sh` — 书库里的入口
- `documents/ankio-tools/` — 菜单（`menu.json`、`config.xml`、`KUAL.cfg`）、功能脚本、`koreader_autostart_worker.sh`
- `documents/ankio-tools/kual-next/` — 菜单启动器 [KUAL Next](https://github.com/thiagokokada/kual-next) 0.3.0（kindlehf）及字体、许可证，来源见 `SOURCE.txt`
- `documents/ankio-tools/icons/` — 脚本图标

## 安装（MTP）

解压后，把 `documents` 文件夹复制到 Kindle 存储根目录并合并。不要把整个 `Ankio-Kindle-Tools` 文件夹放进 documents。不要再把官方 `KUAL Next.sh` 拷进 documents。本包不会删除你设备上的已有文件；若书库里还留着以前那些单独的 `.sh`，可自行移走。

弹出后等图书馆刷新，点「Ankio工具箱」。

## 菜单（英文）

- Start KOReader — 官方 `koreader.sh --kual`（保留原生框架）
- Start KOReader (no framework) — 官方 `koreader.sh --kual --framework_stop`
- View status and logs — 写可读报告到 `/mnt/us/kindle-diagnostics/status-latest.txt`（MTP 可看）。同时写入 KUAL 固定日志 `/var/tmp/kual-next.log`。在菜单底部 KUAL 项里选 Save and reset KUAL log，会把该日志存成书库里的 `KUAL-*.txt`，可当文本打开阅读。
- Diagnostics / Disable auto update / Restore auto update / Enable or Disable KOReader autostart / Start or Stop Telnet — 与此前相同

KOReader 启动：不重装。若 `koreader.sh` 不存在则不启动；若已在运行则不重复启动。菜单用 exitmenu 只登记白名单动作，等官方 `launch.sh` 完成框架恢复后再启动，避免和 KUAL Next 抢框架导致白屏。未在本机 PW12 / 5.20.2.0.1 实测。

官方菜单字体不含汉字，故菜单为英文；书库入口仍是「Ankio工具箱」。启动器自带 Sort / Save and reset KUAL log / Quit。

## 许可

随包的 KUAL Next、FBInk、jsmn、yxml、Noto 字体分别遵循各自许可证，全文见 `kual-next/LICENSES/`。

## Telnet 与更新

Telnet 默认不启用。只建议在可信网络临时使用（无密码、不加密、root）。关闭不保证已建立会话断开。禁用自动更新后请先检查有无已下载包，再手动重启；不能永久阻断。开启 KOReader 自启动时，worker 会被复制到 `/mnt/us/koreader/`；安装后请手动重启；白屏时可在存储根目录新建 `DISABLE_KOREADER_AUTOSTART`。

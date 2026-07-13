# ImmortalWrt ImageBuilder — Cudy TR3000

基于 [wukongdaily/ImmortalWrt-ImageBuilder](https://github.com/wukongdaily/ImmortalWrt-ImageBuilder) 的 Cudy TR3000 v1 定制 ImageBuilder 工作流，通过 GitHub Actions 自动化构建 ImmortalWrt 固件。

**⚠️ 声明：本项目为个人独立维护的第三方脚本，与 ImmortalWrt 官方无关。**

## 构建目标

| 设备 | 型号 | 平台 |
|---|---|---|
| Cudy TR3000 v1 | `cudy_tr3000-v1-ubootmod` | MediaTek MT7981 (Filogic 820) |
| Cudy TR3000 v1 (标准) | `cudy_tr3000-v1` | MediaTek MT7981 |
| Cudy TR3000 v1 (256MB) | `cudy_tr3000-256mb-v1` | MediaTek MT7981 |

## 预装特性

- **OpenClash**: 预置 clash_meta 内核 + GeoIP/GeoSite 规则
- **AdGuard Home**: DNS 去广告（默认阿里 DNS）
- **文件共享**: ksmbd (SMB) + WSDD2
- **DDNS + WOL**: 动态域名 + 网络唤醒
- **UPnP**: miniupnpd-nftables
- **监控**: Bandix 流量统计
- **主题**: Argon + Aurora 双主题
- **存储**: 自动挂载 + exFAT/NTFS3 支持

## 构建方式

### GitHub Actions（推荐）

1. Fork 本仓库
2. 进入 Actions → Build Wireless ImmortalWrt
3. 选择设备 `cudy_tr3000-v1-ubootmod`
4. 可选: 勾选 PPPoE、Docker、iStore
5. 运行构建
6. 下载 Release 产物

### 本地构建

```bash
git clone -b tr3000-custom --single-branch \
  https://github.com/ccAzy/ImmortalWrt-ImageBuilder.git
```

使用 ImageBuilder 容器执行 `mediatek-filogic/build24.sh`。

## 包管理

- `TR3000-PACKAGES.txt` — TR3000 预装包清单
- `shell/custom-packages.sh` — 可选第三方包目录（默认全部注释）
- `files/etc/` — 自定义配置文件（sysctl、防火墙、AdGuardHome、NAT应急）

## 自定义配置

| 文件 | 用途 |
|---|---|
| `files/etc/sysctl.conf` | TCP BBR + 缓冲区优化 + conntrack |
| `files/etc/firewall.user` | iptables 应急 NAT（fw4 故障兜底） |
| `files/etc/adguardhome.yaml` | AdGuard Home DNS 默认配置 |
| `files/etc/init.d/nat-fix` | 应急 NAT 服务脚本 |
| `custom/firewall` | nftables 防火墙规则（含 OpenClash/ZeroTier） |
| `custom/dhcp` | DHCP 配置 |
| `custom/adguardhome` | AdGuard Home Web UI 配置 |

## 默认参数

- **默认 IP**: `192.168.6.1`（可通过 CI 参数自定义）
- **用户**: `root`，密码无
- **固件大小**: 1GB（默认）

## 相关仓库

- [ccAzy/immortalwrt](https://github.com/ccAzy/immortalwrt) — TR3000 源码编译配置
- [padavanonly/immortalwrt-mt798x-6.6](https://github.com/padavanonly/immortalwrt-mt798x-6.6) — 上游 MT798x 内核适配
- [wukongdaily/ImmortalWrt-ImageBuilder](https://github.com/wukongdaily/ImmortalWrt-ImageBuilder) — ImageBuilder 上游

## 致谢

- [ImmortalWrt](https://github.com/immortalwrt) — OpenWrt 中国大陆优化分支
- [wukongdaily](https://github.com/wukongdaily) — ImageBuilder CI 工作流框架
- [padavanonly](https://github.com/padavanonly) — MT798x 6.6 内核适配
- [vernesong/OpenClash](https://github.com/vernesong/OpenClash) — Clash 客户端

## License

本项目脚本和配置文件采用 GPL-3.0 许可证。固件本身使用 ImmortalWrt (GPL-2.0)。
详见 [LICENSE](LICENSE)。

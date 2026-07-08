#!/bin/sh
# TR3000 自定义初始化
# 首次刷入后执行

# 确保 nat-fix 可执行
chmod +x /etc/init.d/nat-fix

# 启用 nat-fix 和 firewall 自启
[ -x /etc/init.d/nat-fix ] && /etc/init.d/nat-fix enable
[ -x /etc/init.d/firewall ] && /etc/init.d/firewall enable

# 临时修复内核模块不匹配（不阻塞启动）
sed -i 's/kmod-nft-core//g' /etc/config/firewall 2>/dev/null

exit 0

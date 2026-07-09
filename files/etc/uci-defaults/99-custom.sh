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

# === OpenClash 优化守护 ===
# 创建覆写脚本，每次 OpenClash 重载配置后自动应用优化
cat > /etc/openclash/custom/openclash_custom_overwrite.sh << 'OCEOF'
#!/bin/sh
. /usr/share/openclash/ruby.sh
. /usr/share/openclash/log.sh
. /lib/functions.sh

LOG_TIP "Start Running Custom Overwrite Scripts..."
LOGTIME=$(echo $(date "+%Y-%m-%d %H:%M:%S"))

YAML="/etc/openclash/config/良心云.yaml"

# 关闭 unified-delay
if grep -q "unified-delay: true" "$YAML"; then
  sed -i "s/unified-delay: true/unified-delay: false/" "$YAML"
  LOG_TIP "unified-delay → false"
fi

# geodata-mode
if ! grep -q "^geodata-mode:" "$YAML"; then
  sed -i "/^mode:/i\geodata-mode: true" "$YAML"
  LOG_TIP "geodata-mode added"
fi

# sniffer
if ! grep -q "^sniffer:" "$YAML" 2>/dev/null || grep -q "^sniffer:$" "$YAML" 2>/dev/null; then
  sed -i "/^sniffer:/d" "$YAML" 2>/dev/null
  sed -i "/^mode: rule/a\sniffer:\n  enable: true\n  sniffing: [tls, http]\n  port-whitelist: [80, 443, 8000-9000]\n  force-dns-mapping: true\n  parse-pure-ip: true" "$YAML"
  LOG_TIP "sniffer added"
fi

# tcp-keep-alive
if ! grep -q "^tcp-keep-alive-interval:" "$YAML"; then
  sed -i "/^tcp-concurrent:/a\tcp-keep-alive-interval: 600" "$YAML"
  LOG_TIP "keep-alive added"
fi

# fake-ip-filter
if ! grep -q "fake-ip-filter:" "$YAML"; then
  sed -i "/fake-ip-range: 198.18.0.1\/16/a\    fake-ip-filter: [\".lan\", \"*.local\", \"ntp.*\", \"time.*\", \"localhost\"]" "$YAML"
  LOG_TIP "fake-ip-filter added"
fi

LOG_TIP "TR3000 OpenClash 优化守护完成"
exit 0
OCEOF
chmod +x /etc/openclash/custom/openclash_custom_overwrite.sh

exit 0

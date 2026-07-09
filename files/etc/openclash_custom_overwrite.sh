#!/bin/sh
. /usr/share/openclash/ruby.sh
. /usr/share/openclash/log.sh
. /lib/functions.sh

# This script is called by /etc/init.d/openclash
# Add your custom overwrite scripts here, they will be take effict after the OpenClash own srcipts

LOG_TIP "Start Running Custom Overwrite Scripts..."
LOGTIME=$(echo $(date "+%Y-%m-%d %H:%M:%S"))

# === TR3000 优化守护 (2026-07-09) ===
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

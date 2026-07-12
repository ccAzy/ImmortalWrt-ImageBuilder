#!/bin/bash
source shell/custom-packages.sh
source shell/switch_repository.sh
# 该文件实际为imagebuilder容器内的build.sh

#echo "✅ 你选择了第三方软件包：$CUSTOM_PACKAGES"
# 下载 run 文件仓库
echo "🔄 正在同步第三方软件仓库 Cloning run file repo..."
git clone --depth=1 https://github.com/wukongdaily/store.git /tmp/store-run-repo

# 拷贝 run/arm64 下所有 run 文件和ipk文件 到 extra-packages 目录
mkdir -p /home/build/immortalwrt/extra-packages
cp -r /tmp/store-run-repo/run/arm64/* /home/build/immortalwrt/extra-packages/

echo "✅ Run files copied to extra-packages:"
ls -lh /home/build/immortalwrt/extra-packages/*.run
# 解压并拷贝ipk到packages目录
sh shell/prepare-packages.sh
ls -lah /home/build/immortalwrt/packages/
# 添加架构优先级信息
sed -i '1i\
arch aarch64_generic 10\n\
arch aarch64_cortex-a53 15' repositories.conf

# 添加 Kwrt 第三方包源 (wrtbwmon/eqos 等)
if [ -f shell/kwrt-feed.conf ]; then
  cat shell/kwrt-feed.conf >> repositories.conf
  echo "✅ Kwrt feed added"
fi


# yml 传入的路由器型号 PROFILE
echo "Building for profile: $PROFILE"

echo "Include Docker: $INCLUDE_DOCKER"
echo "Create pppoe-settings"
mkdir -p  /home/build/immortalwrt/files/etc/config

# 创建pppoe配置文件 yml传入pppoe变量————>pppoe-settings文件
cat << EOF > /home/build/immortalwrt/files/etc/config/pppoe-settings
enable_pppoe=${ENABLE_PPPOE}
pppoe_account=${PPPOE_ACCOUNT}
pppoe_password=${PPPOE_PASSWORD}
EOF

echo "cat pppoe-settings"
cat /home/build/immortalwrt/files/etc/config/pppoe-settings

# 输出调试信息
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting build process..."


# 定义所需安装的包列表 下列插件你都可以自行删减
PACKAGES=""
PACKAGES="$PACKAGES curl luci luci-i18n-base-zh-cn"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
PACKAGES="$PACKAGES luci-theme-argon"
PACKAGES="$PACKAGES luci-app-argon-config"
PACKAGES="$PACKAGES luci-i18n-argon-config-zh-cn"
PACKAGES="$PACKAGES luci-i18n-diskman-zh-cn"
#24.10.0
PACKAGES="$PACKAGES luci-i18n-package-manager-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ttyd-zh-cn"
PACKAGES="$PACKAGES openssh-sftp-server"
# 文件管理器
PACKAGES="$PACKAGES luci-i18n-filemanager-zh-cn"


# 第三方软件包 合并
# ======== shell/custom-packages.sh =======
if [ "$PROFILE" = "glinet_gl-axt1800" ] || [ "$PROFILE" = "glinet_gl-ax1800" ]; then
    # 这2款 暂时不支持第三方插件的集成 snapshot版本太高 opkg换成apk包管理器 6.12内核 
    echo "Model:$PROFILE not support third-parted packages"
    PACKAGES="$PACKAGES -luci-i18n-diskman-zh-cn luci-i18n-homeproxy-zh-cn"
else
    echo "Other Model:$PROFILE"
    PACKAGES="$PACKAGES $CUSTOM_PACKAGES"
fi

# 判断是否需要编译 Docker 插件
if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
    echo "Adding package: luci-i18n-dockerman-zh-cn"
fi

# 若构建openclash 则添加内核 (带重试+校验+缓存复用)
if echo "$PACKAGES" | grep -q "luci-app-openclash"; then
    echo "✅ 已选择 luci-app-openclash，添加 openclash core"
    mkdir -p files/etc/openclash/core

    # 通用下载函数: 重试3次 + 校验非空
    dl_retry() {
      local url="$1" dst="$2" label="$3"
      for i in 1 2 3; do
        echo "  [$label] 下载 (第${i}次): $url"
        wget -q --timeout=60 -O "$dst" "$url" && [ -s "$dst" ] && echo "  [$label] ✅ 成功" && return 0
        echo "  [$label] ⚠️ 失败, ${i}/3"
        sleep 5
      done
      echo "  [$label] ❌ 3次均失败, 继续构建(固件中 OpenClash 可能缺少内核/规则)"
      return 1
    }

    # 缓存检查: GitHub Actions cache 恢复的文件跳过下载
    cached_skip() {
      local f="$1" label="$2"
      if [ -s "$f" ]; then
        echo "  [$label] ✅ 命中缓存 ($(wc -c < "$f") bytes), 跳过下载"
        return 0
      fi
      return 1
    }

    # Download clash_meta
    if cached_skip files/etc/openclash/core/clash_meta "clash_meta"; then
      chmod +x files/etc/openclash/core/clash_meta
    else
      META_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-arm64.tar.gz"
      META_TMP=$(mktemp)
      dl_retry "$META_URL" "$META_TMP" "clash_meta" && {
        tar xOvz "$META_TMP" > files/etc/openclash/core/clash_meta 2>/dev/null
        if [ -s files/etc/openclash/core/clash_meta ]; then
          chmod +x files/etc/openclash/core/clash_meta
          echo "  [clash_meta] ✅ 已解压 ($(wc -c < files/etc/openclash/core/clash_meta) bytes)"
        else
          echo "  [clash_meta] ❌ 解压为空, OpenClash 可能无法启动"
        fi
        rm -f "$META_TMP"
      }
    fi

    # Download GeoIP and GeoSite (优先缓存)
    cached_skip files/etc/openclash/GeoIP.dat "GeoIP" || \
      dl_retry "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat" \
        files/etc/openclash/GeoIP.dat "GeoIP"
    cached_skip files/etc/openclash/GeoSite.dat "GeoSite" || \
      dl_retry "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat" \
        files/etc/openclash/GeoSite.dat "GeoSite"

    # Download latest openclash ipk (不缓存 — 始终拉最新版)
    echo "  [OpenClash ipk] 查询最新版本..."
    URL=$(curl -s --connect-timeout 15 --retry 2 \
      https://api.github.com/repos/vernesong/OpenClash/releases/latest \
      | grep "browser_download_url.*ipk" \
      | head -n1 | cut -d '"' -f 4)
    if [ -n "$URL" ]; then
      echo "  [OpenClash ipk] URL: $URL"
      dl_retry "$URL" "/home/build/immortalwrt/packages/$(basename "$URL")" "OpenClash ipk"
    else
      echo "  [OpenClash ipk] ❌ 获取下载地址失败(GitHub API 可能限流), 将使用仓库自带版本"
    fi
else
    echo "⚪️ 未选择 luci-app-openclash"
fi

# 打印文件清单供调试
echo "📦 OpenClash 文件:"
find files/etc/openclash/ -type f -exec ls -lh {} \; 2>/dev/null || echo "  (无)"


# 构建镜像
echo "$(date '+%Y-%m-%d %H:%M:%S') - Building image with the following packages:"
echo "$PACKAGES"



# 打包前压缩: strip 二进制 + 删非中文语言
find /home/build/immortalwrt/build_dir/target-aarch64_cortex-a53_musl/root-mediatek/ -name "*.lmo" ! -name "*zh-cn*" -delete 2>/dev/null || true
find /home/build/immortalwrt/build_dir/target-aarch64_cortex-a53_musl/root-mediatek/ -type f -executable -exec strip --strip-unneeded {} \; 2>/dev/null || true

make image PROFILE=$PROFILE PACKAGES="$PACKAGES" FILES="/home/build/immortalwrt/files" SQUASHFSOPT="-b 256k -comp xz -Xbcj arm -noappend -Xdict-size 1M"

if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Build failed!"
    exit 1
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully."
fi


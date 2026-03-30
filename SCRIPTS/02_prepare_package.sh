#!/bin/bash
clear

### 基础部分 ###
# 使用 O2 级别的优化
sed -i 's/Os/O2/g' include/target.mk
# 移除非必要插件
sed -i '/luci-app-uhttpd \\/d' include/target.mk
sed -i '/luci-app-ddns \\/d' include/target.mk
# 更新 Feeds
./scripts/feeds update -a
cp -a $GITHUB_WORKSPACE/FILES/node-pnpm feeds/packages/lang/
./scripts/feeds update packages
./scripts/feeds install -a

# 定义内核版本
KERNEL_VERSION="6.12"

# NTP
sed -i 's/0.openwrt.pool.ntp.org/ntp1.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/1.openwrt.pool.ntp.org/ntp2.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/2.openwrt.pool.ntp.org/time1.cloud.tencent.com/g' package/base-files/files/bin/config_generate
sed -i 's/3.openwrt.pool.ntp.org/time2.cloud.tencent.com/g' package/base-files/files/bin/config_generate

# Docker 容器
rm -rf ./feeds/luci/applications/luci-app-dockerman
cp -rf ../dockerman/applications/luci-app-dockerman ./feeds/luci/applications/luci-app-dockerman
sed -i '/auto_start/d' feeds/luci/applications/luci-app-dockerman/root/etc/uci-defaults/luci-app-dockerman
pushd feeds/packages
wget -qO- https://github.com/openwrt/packages/commit/e2e5ee69.patch | patch -p1
wget -qO- https://github.com/openwrt/packages/pull/20054.patch | patch -p1
popd
sed -i '/sysctl.d/d' feeds/packages/utils/dockerd/Makefile
rm -rf ./feeds/luci/collections/luci-lib-docker
cp -rf ../docker_lib/collections/luci-lib-docker ./feeds/luci/collections/luci-lib-docker

# ============================================================================================================
# 自定义DIY⬇⬇⬇
# default LAN IP
sed -i "s/192.168.1.1/192.168.5.88/g" package/base-files/files/bin/config_generate

# clash_meta
mkdir -p files/etc/openclash/core
CLASH_META_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-arm64.tar.gz"
wget -qO- $CLASH_META_URL | tar xOvz > files/etc/openclash/core/clash_meta
chmod +x files/etc/openclash/core/clash*

# clash_config
mkdir -p files/etc/config
wget -qO- https://raw.githubusercontent.com/Kwonelee/Kwonelee/refs/heads/main/rule/openclash > files/etc/config/openclash

# 集成设备无线
#mkdir -p package/base-files/files/lib/firmware/brcm
#cp -a $GITHUB_WORKSPACE/FILES/firmware/brcm/* package/base-files/files/lib/firmware/brcm/

# 处理Rust报错
sed -i 's/ci-llvm=true/ci-llvm=false/g' feeds/packages/lang/rust/Makefile

# golang 1.26
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

# node - prebuilt
rm -rf feeds/packages/lang/node
git clone https://github.com/sbwml/feeds_packages_lang_node-prebuilt feeds/packages/lang/node -b packages-24.10

# zerotier
rm -rf feeds/packages/net/zerotier
git clone https://github.com/sbwml/feeds_packages_net_zerotier feeds/packages/net/zerotier

# 移除待替换插件
#rm -rf feeds/packages/net/adguardhome
rm -rf feeds/luci/applications/luci-app-filebrowser
rm -rf feeds/luci/applications/luci-app-radicale

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package/new
  cd .. && rm -rf $repodir
}

# 常见插件
git_sparse_clone master https://github.com/vernesong/OpenClash luci-app-openclash
git_sparse_clone main https://github.com/gdy666/luci-app-lucky luci-app-lucky lucky
git_sparse_clone main https://github.com/sbwml/luci-app-openlist2 luci-app-openlist2 openlist2
git_sparse_clone main https://github.com/sbwml/openwrt_pkgs luci-app-cpufreq luci-app-diskman luci-app-zerotier
git_sparse_clone main https://github.com/Kwonelee/openwrt-packages luci-app-ramfree filebrowser luci-app-filebrowser-go
FB_VERSION="$(curl -s https://github.com/filebrowser/filebrowser/tags | grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 | sed 's/^v//')"
sed -i "s/2.54.0/$FB_VERSION/g" package/new/filebrowser/Makefile
#git clone --depth=1 -b master https://github.com/w9315273/luci-app-adguardhome package/new/luci-app-adguardhome
# 自定义DIY⬆⬆⬆
# ============================================================================================================

### 最后的收尾工作 ###
# 生成默认配置及缓存
rm -rf .config
sed -i 's,CONFIG_WERROR=y,# CONFIG_WERROR is not set,g' target/linux/generic/config-${KERNEL_VERSION}

./scripts/feeds update -i
./scripts/feeds install -a

#exit 0

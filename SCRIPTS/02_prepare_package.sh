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

# ============================================================================================================
# 自定义DIY⬇⬇⬇
# TTYD
sed -i 's/procd_set_param stdout 1/procd_set_param stdout 0/g' feeds/packages/utils/ttyd/files/ttyd.init
sed -i 's/procd_set_param stderr 1/procd_set_param stderr 0/g' feeds/packages/utils/ttyd/files/ttyd.init

# samba4 default config
sed -i 's/invalid users = root/#invalid users = root/g' feeds/packages/net/samba4/files/smb.conf.template

# NTP
sed -i 's/0.openwrt.pool.ntp.org/ntp1.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/1.openwrt.pool.ntp.org/ntp2.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/2.openwrt.pool.ntp.org/time1.cloud.tencent.com/g' package/base-files/files/bin/config_generate
sed -i 's/3.openwrt.pool.ntp.org/time2.cloud.tencent.com/g' package/base-files/files/bin/config_generate

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
wget https://github.com/rust-lang/rust/commit/cdae267.patch -O feeds/packages/lang/rust/patches/cdae267.patch
sed -i 's/--set=llvm\.download-ci-llvm=true/--set=llvm.download-ci-llvm=false/' feeds/packages/lang/rust/Makefile

# golang 1.26
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

# node - prebuilt
#rm -rf feeds/packages/lang/node
#git clone https://github.com/sbwml/feeds_packages_lang_node feeds/packages/lang/node -b packages-24.10

# zerotier
rm -rf feeds/packages/net/zerotier
git clone https://github.com/sbwml/feeds_packages_net_zerotier feeds/packages/net/zerotier

# Docker
#rm -rf feeds/luci/applications/luci-app-dockerman
#git clone https://github.com/sbwml/luci-app-dockerman -b openwrt-25.12 feeds/luci/applications/luci-app-dockerman
#rm -rf feeds/packages/utils/{docker,dockerd,containerd,runc}
#git clone https://github.com/sbwml/packages_utils_docker feeds/packages/utils/docker
#git clone https://github.com/sbwml/packages_utils_dockerd feeds/packages/utils/dockerd
#git clone https://github.com/sbwml/packages_utils_containerd feeds/packages/utils/containerd
#git clone https://github.com/sbwml/packages_utils_runc feeds/packages/utils/runc

# 移除待替换插件
rm -rf feeds/packages/net/adguardhome
rm -rf feeds/luci/applications/luci-app-adguardhome
rm -rf feeds/luci/applications/luci-app-filebrowser
#rm -rf feeds/luci/applications/luci-app-radicale

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
cp -f $GITHUB_WORKSPACE/FILES/lucky_status.htm package/new/luci-app-lucky/luasrc/view/lucky/lucky_status.htm
git_sparse_clone main https://github.com/sbwml/luci-app-openlist2 luci-app-openlist2 openlist2
git_sparse_clone main https://github.com/sbwml/openwrt_pkgs luci-app-cpufreq luci-app-diskman luci-app-zerotier
git_sparse_clone main https://github.com/Kwonelee/openwrt-packages luci-app-ramfree filebrowser luci-app-filebrowser-go
FB_VERSION="$(curl -s https://github.com/filebrowser/filebrowser/tags | grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 | sed 's/^v//')"
sed -i "s/2.54.0/$FB_VERSION/g" package/new/filebrowser/Makefile
#git clone --depth=1 -b master https://github.com/w9315273/luci-app-adguardhome package/new/luci-app-adguardhome
#git_sparse_clone main https://github.com/sirpdboy/luci-app-adguardhome luci-app-adguardhome
# 自定义DIY⬆⬆⬆
# ============================================================================================================

### 最后的收尾工作 ###
# 生成默认配置及缓存
rm -rf .config
sed -i 's,CONFIG_WERROR=y,# CONFIG_WERROR is not set,g' target/linux/generic/config-${KERNEL_VERSION}

./scripts/feeds update -i
./scripts/feeds install -a

#exit 0

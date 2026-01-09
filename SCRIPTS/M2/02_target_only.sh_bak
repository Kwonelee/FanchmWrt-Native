#!/bin/bash -e
clear

# 使用特定的优化
sed -i 's,-mcpu=generic,-march=armv8-a+crc+crypto,g' include/target.mk
sed -i 's,kmod-r8168,kmod-r8169,g' target/linux/rockchip/image/armv8.mk

#Vermagic
latest_version="$(curl -s https://github.com/openwrt/openwrt/tags | grep -Eo "v[0-9\.]+\-*r*c*[0-9]*.tar.gz" | sed -n '/[2-9][5-9]/p' | sed -n 1p | sed 's/v//g' | sed 's/.tar.gz//g')"
wget https://downloads.openwrt.org/releases/${latest_version}/targets/rockchip/armv8/profiles.json
jq -r '.linux_kernel.vermagic' profiles.json >.vermagic
sed -i -e 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk

# ============================================================================================================
# 添加设备⬇⬇⬇
echo -e "\\ndefine Device/firefly_station-m2
  \$(Device/rk3566)
  DEVICE_VENDOR := Firefly
  DEVICE_MODEL := Station M2 / RK3566 ROC PC
  DEVICE_DTS := rk3566-roc-pc
  SUPPORTED_DEVICES += firefly,rk3566-roc-pc firefly,station-m2
  UBOOT_DEVICE_NAME := station-m2-rk3566
  DEVICE_PACKAGES := kmod-nvme kmod-scsi-core
endef
TARGET_DEVICES += firefly_station-m2" >> target/linux/rockchip/image/armv8.mk

# 替换package/boot/uboot-rockchip/Makefile
cp -f $GITHUB_WORKSPACE/FILES/uboot-rockchip/Makefile package/boot/uboot-rockchip/Makefile

# 复制uboot配置、dts到package/boot/uboot-rockchip
mkdir -p package/boot/uboot-rockchip/src/arch/arm/dts
mkdir -p package/boot/uboot-rockchip/src/configs
cp -f $GITHUB_WORKSPACE/FILES/dts/rk3566-roc-pc.dts package/boot/uboot-rockchip/src/arch/arm/dts/
cp -f $GITHUB_WORKSPACE/FILES/uboot-rockchip/rk3566-station-m2-u-boot.dtsi package/boot/uboot-rockchip/src/arch/arm/dts/
cp -f $GITHUB_WORKSPACE/FILES/uboot-rockchip/station-m2-rk3566_defconfig package/boot/uboot-rockchip/src/configs/

# 复制dts到files/arch/arm64/boot/dts/rockchip
mkdir -p target/linux/rockchip/files/arch/arm64/boot/dts/rockchip
cp -f $GITHUB_WORKSPACE/FILES/dts/rk3566-roc-pc.dts target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/
# 添加设备⬆⬆⬆
# ============================================================================================================

# ============================================================================================================
# 自定义DIY⬇⬇⬇
# default LAN IP
sed -i "s/192.168.1.1/192.168.5.88/g" package/base-files/files/bin/config_generate

# luci-theme-bootstrap
sed -i 's/font-size: 13px/font-size: 14px/g' feeds/luci/themes/luci-theme-bootstrap/htdocs/luci-static/bootstrap/cascade.css
sed -i 's/9.75px/10.75px/g' feeds/luci/themes/luci-theme-bootstrap/htdocs/luci-static/bootstrap/cascade.css

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

# 移除待替换插件
rm -rf ./package/new/{luci-theme-argon,luci-app-argon-config,OpenClash,addition-trans-zh}
rm -rf ./package/new/openwrt_pkgs/luci-app-adguardhome
rm -rf feeds/packages/net/adguardhome
rm -rf feeds/luci/applications/{luci-app-dockerman,luci-app-filebrowser}
rm -rf feeds/packages/utils/{docker,dockerd,containerd,runc}

# 修改filebrowser
sed -i 's/2.31.2/2.53.1/g' package/new/openwrt_pkgs/filebrowser/Makefile
sed -i 's/admin/OpenWrt/g' package/new/openwrt_pkgs/luci-app-filebrowser-go/root/etc/config/filebrowser
sed -i 's/services/nas/g' package/new/openwrt_pkgs/luci-app-filebrowser-go/luasrc/view/filebrowser/filebrowser_log.htm
sed -i 's/services/nas/g' package/new/openwrt_pkgs/luci-app-filebrowser-go/luasrc/view/filebrowser/filebrowser_status.htm
sed -i 's/services/nas/g' package/new/openwrt_pkgs/luci-app-filebrowser-go/luasrc/controller/filebrowser.lua
sed -i 's/_("File Browser"), 100/_("File Browser"), 1/' package/new/openwrt_pkgs/luci-app-filebrowser-go/luasrc/controller/filebrowser.lua
sed -i '/local page.*filebrowser.*1)/i\
entry({"admin", "nas"}, firstchild(), "NAS", 44).dependent = false' package/new/openwrt_pkgs/luci-app-filebrowser-go/luasrc/controller/filebrowser.lua

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package/new
  cd .. && rm -rf $repodir
}

# Docker
git clone https://git.cooluc.com/sbwml/luci-app-dockerman -b nft feeds/luci/applications/luci-app-dockerman
git clone https://git.cooluc.com/sbwml/packages_utils_docker feeds/packages/utils/docker
git clone https://git.cooluc.com/sbwml/packages_utils_dockerd feeds/packages/utils/dockerd
git clone https://git.cooluc.com/sbwml/packages_utils_containerd feeds/packages/utils/containerd
git clone https://git.cooluc.com/sbwml/packages_utils_runc feeds/packages/utils/runc
# Theme
#git clone --depth=1 -b master https://github.com/jerrykuku/luci-theme-argon package/new/luci-theme-argon
#git clone --depth=1 -b master https://github.com/jerrykuku/luci-app-argon-config package/new/luci-app-argon-config
git clone --depth=1 -b openwrt-25.12 https://github.com/sbwml/luci-theme-argon package/new/luci-theme-argon
curl -s https://raw.githubusercontent.com/Kwonelee/Kwonelee/main/beifen/OP-bak/argon/bg.webp > package/new/luci-theme-argon/luci-theme-argon/htdocs/luci-static/argon/img/bg.webp
sed -i "s/option primary '#5e72e4'/option primary '#8760f7'/g" package/new/luci-theme-argon/luci-app-argon-config/root/etc/config/argon
sed -i "s/option dark_primary '#483d8b'/option dark_primary '#6727dc'/g" package/new/luci-theme-argon/luci-app-argon-config/root/etc/config/argon
sed -i "s/#2e2b60/#7640f0/g" package/new/luci-theme-argon/luci-app-argon-config/root/etc/config/argon
sed -i "s/normal/dark/g" package/new/luci-theme-argon/luci-app-argon-config/root/etc/config/argon
sed -i "s/0.2/0.5/g" package/new/luci-theme-argon/luci-app-argon-config/root/etc/config/argon
# 常见插件
git_sparse_clone master https://github.com/vernesong/OpenClash luci-app-openclash
git_sparse_clone main https://github.com/gdy666/luci-app-lucky luci-app-lucky lucky
git_sparse_clone main https://github.com/sbwml/luci-app-openlist2 luci-app-openlist2 openlist2
git clone --depth=1 -b main https://github.com/Kwonelee/addition-trans-zh package/new/addition-trans-zh
git clone --depth=1 -b master https://github.com/w9315273/luci-app-adguardhome package/new/luci-app-adguardhome
# 自定义DIY⬆⬆⬆
# ============================================================================================================

# 预配置一些插件
mkdir -p ./files/etc/hotplug.d/net
cp -rf ../PATCH/files/etc/hotplug.d/net/01-maximize_nic_rx_tx_buffers ./files/etc/hotplug.d/net/

find ./ -name *.orig | xargs rm -f
find ./ -name *.rej | xargs rm -f

#exit 0

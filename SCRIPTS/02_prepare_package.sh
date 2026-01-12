#!/bin/bash
clear

### 基础部分 ###
# 使用 O2 级别的优化
#sed -i 's/Os/O2/g' include/target.mk
# 更新 Feeds
./scripts/feeds update -a
./scripts/feeds install -a
# 移除 SNAPSHOT 标签
#sed -i 's,-SNAPSHOT,,g' include/version.mk
#sed -i 's,-SNAPSHOT,,g' package/base-files/image-config.in
#sed -i '/CONFIG_BUILDBOT/d' include/feeds.mk
#sed -i 's/;)\s*\\/; \\/' include/feeds.mk

### 最后的收尾工作 ###
# Lets Fuck
#mkdir -p package/base-files/files/usr/bin
#cp -rf ../OpenWrt-Add/fuck ./package/base-files/files/usr/bin/fuck
# 生成默认配置及缓存
rm -rf .config
sed -i 's,CONFIG_WERROR=y,# CONFIG_WERROR is not set,g' target/linux/generic/config-6.6

#exit 0

#!/bin/bash

#安装和更新软件包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local REPO_NAME=$(echo $PKG_REPO | cut -d '/' -f 2)

	rm -rf $(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune)
# 移除要替换的包
rm -rf feeds/packages/net/v2ray-geodata
rm -rf feeds/packages/net/mosdns
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/packages/net/smartdns
rm -rf feeds/packages/net/msd_lite
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/themes/luci-theme-netgear
rm -rf feeds/luci/applications/luci-app-netdata

	git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git"
#添加需要的插件
#git clone --depth=1 https://github.com/kongfl888/luci-app-adguardhome package/luci-app-adguardhome
#git clone --depth=1 https://github.com/ilxp/luci-app-ikoolproxy package/luci-app-ikoolproxy
git clone --depth=1 https://github.com/esirplayground/luci-app-poweroff package/luci-app-poweroff
#git clone --depth=1 https://github.com/destan19/OpenAppFilter package/OpenAppFilter
git clone --depth=1 https://github.com/Jason6111/luci-app-netdata package/luci-app-netdata
git clone --depth=1 https://github.com/ximiTech/luci-app-msd_lite package/luci-app-msd_lite
git clone --depth=1 https://github.com/ximiTech/msd_lite package/msd_lite
#git clone --depth=1 https://github.com/sbwml/luci-app-alist package/luci-app-alist

	if [[ $PKG_SPECIAL == "pkg" ]]; then
		cp -rf $(find ./$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune) ./
		rm -rf ./$REPO_NAME/
	elif [[ $PKG_SPECIAL == "name" ]]; then
		mv -f $REPO_NAME $PKG_NAME
	fi
}

#UPDATE_PACKAGE "包名" "项目地址" "项目分支" "pkg/name，可选，pkg为从大杂烩中单独提取包名插件；name为重命名为包名"
UPDATE_PACKAGE "design" "gngpp/luci-theme-design" "js"
UPDATE_PACKAGE "design-config" "gngpp/luci-app-design-config" "master"
UPDATE_PACKAGE "argon" "jerrykuku/luci-theme-argon" "master"
UPDATE_PACKAGE "argon-config" "jerrykuku/luci-app-argon-config" "master"

#smartdns相关
git clone --depth=1 https://github.com/pymumu/openwrt-smartdns package/smartdns
git clone --depth=1 https://github.com/pymumu/luci-app-smartdns package/luci-app-smartdns
#mosdns
git clone --depth=1 https://github.com/sbwml/v2ray-geodata package/v2ray-geodata
#git clone --depth=1 -b 20.x https://github.com/sbwml/packages_lang_golang packages/lang/golang
git clone --depth=1 -b v5 https://github.com/sbwml/luci-app-mosdns package/mosdns

#科学插件
git clone --depth=1 -b main https://github.com/fw876/helloworld package/luci-app-ssr-plus
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall package/luci-app-passwall
#git clone --depth=1 -b luci-smartdns-dev https://github.com/xiaorouji/openwrt-passwall package/luci-app-passwall
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall2 package/luci-app-passwall2
git clone --depth=1 -b master https://github.com/vernesong/OpenClash package/luci-app-openclash



UPDATE_PACKAGE "advancedplus" "VIKINGYFY/luci-app-advancedplus" "main"
UPDATE_PACKAGE "gecoosac" "lwb1978/openwrt-gecoosac" "main"

if [[ $WRT_REPO != *"lede"* ]]; then
	UPDATE_PACKAGE "daed" "QiuSimons/luci-app-daed" "master"
	UPDATE_PACKAGE "homeproxy" "VIKINGYFY/homeproxy" "main"
	UPDATE_PACKAGE "mihomo" "morytyann/OpenWrt-mihomo" "main" "pkg"
fi

if [[ $WRT_REPO == *"openwrt-6.x"* ]]; then
	UPDATE_PACKAGE "qmi-wwan" "immortalwrt/wwan-packages" "master" "pkg"
fi

#更新软件包版本
UPDATE_VERSION() {
	local PKG_NAME=$1
	local PKG_MARK=${2:-not}
	local PKG_FILES=$(find ./ ../feeds/packages/ -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")

	echo " "

	if [ -z "$PKG_FILES" ]; then
		echo "$PKG_NAME not found!"
		return
	fi

	echo "$PKG_NAME version update has started!"

	for PKG_FILE in $PKG_FILES; do
		local PKG_REPO=$(grep -Pho 'PKG_SOURCE_URL:=https://.*github.com/\K[^/]+/[^/]+(?=.*)' $PKG_FILE | head -n 1)
		local PKG_VER=$(curl -sL "https://api.github.com/repos/$PKG_REPO/releases" | jq -r "map(select(.prerelease|$PKG_MARK)) | first | .tag_name")
		local NEW_VER=$(echo $PKG_VER | sed "s/.*v//g; s/_/./g")
		local NEW_HASH=$(curl -sL "https://codeload.github.com/$PKG_REPO/tar.gz/$PKG_VER" | sha256sum | cut -b -64)

		local OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" "$PKG_FILE")

		echo "$OLD_VER $PKG_VER $NEW_VER $NEW_HASH"

		if [[ $NEW_VER =~ ^[0-9].* ]] && dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
			sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
			sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" "$PKG_FILE"
			echo "$PKG_FILE version has been updated!"
		else
			echo "$PKG_FILE version is already the latest!"
		fi
	done
}

#UPDATE_VERSION "软件包名" "测试版，true，可选，默认为否"
#UPDATE_VERSION "sing-box" "true"

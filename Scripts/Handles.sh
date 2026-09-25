#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

FEEDS_PATH="./feeds"
PACKAGE_PATH="./package"

#修改argon主题字体和颜色
if [ -d "$PACKAGE_PATH/luci-theme-argon" ]; then
	echo " "
	if sed -i "s/primary '.*'/primary '#31a1a1'/g; s/'0.2'/'0.5'/g; s/'none'/'bing'/g; s/'600'/'normal'/g" \
		"$PACKAGE_PATH/luci-theme-argon/luci-app-argon-config/root/etc/config/argon"; then
		echo "theme-argon has been fixed!"
	else
		echo "theme-argon fix failed; continuing!"
	fi
fi

#修改aurora菜单式样
if [ -d "$PACKAGE_PATH/luci-app-aurora-config" ]; then
	echo " "
	if find "$PACKAGE_PATH/luci-app-aurora-config/root/usr/share/aurora/" -type f -name '*.template' -exec \
		sed -i "s/nav_type '.*'/nav_type 'dropdown'/g; s/struct_radius_base '.*'/struct_radius_base '0.125rem'/g" {} +; then
		echo "theme-aurora has been fixed!"
	else
		echo "theme-aurora fix failed; continuing!"
	fi
fi

#修改mini-diskmanager菜单位置
if [ -d "$PACKAGE_PATH/luci-app-mini-diskmanager" ]; then
	echo " "
	if sed -i "s/services/system/g" \
		"$PACKAGE_PATH/luci-app-mini-diskmanager/luci-app-mini-diskmanager/root/usr/share/luci/menu.d/luci-app-mini-diskmanager.json"; then
		echo "mini-diskmanager has been fixed!"
	else
		echo "mini-diskmanager fix failed; continuing!"
	fi
fi

#修改natmapt菜单位置
if [ -d "$PACKAGE_PATH/luci-app-natmapt" ]; then
	echo " "
	if sed -i "s/network/services/g" \
		"$PACKAGE_PATH/luci-app-natmapt/root/usr/share/luci/menu.d/luci-app-natmap.json"; then
		echo "natmapt has been fixed!"
	else
		echo "natmapt fix failed; continuing!"
	fi
fi

#修复Rust编译失败
if [ -d "$FEEDS_PATH/packages/lang/rust" ]; then
	echo " "
	if sed -i 's/ci-llvm=true/ci-llvm=false/g' \
		"$FEEDS_PATH/packages/lang/rust/Makefile"; then
		echo "rust has been fixed!"
	else
		echo "rust fix failed; continuing!"
	fi
fi

# 修復 luci-app-statistics：儲存局部設定時不刪除未修改的設定
STAT_APP="$PKG_PATH/../feeds/luci/applications/luci-app-statistics"
STAT_VIEW="$STAT_APP/htdocs/luci-static/resources/view/statistics"
COLLECTD_JS="$STAT_VIEW/collectd.js"
STAT_CONFIG="$STAT_APP/root/etc/config/luci_statistics"

if [ -d "$STAT_VIEW" ] && [ -f "$COLLECTD_JS" ] && [ -f "$STAT_CONFIG" ]; then
	# 對所有 statistics 設定頁：
	# 1. 預設值不視為可刪除的空值
	# 2. depends() 暫時不成立時保留原 UCI 設定
	while IFS= read -r JS_FILE; do
		if ! grep -Fq 'statistics-save-fix' "$JS_FILE"; then
			sed -i \
				-e "/^[[:space:]]*o\.default[[:space:]]*=/a\\
		o.rmempty = false; // statistics-save-fix" \
				-e "/^[[:space:]]*o\.depends(/a\\
		o.retain = true; // statistics-save-fix" \
				"$JS_FILE"
		fi
	done < <(find "$STAT_VIEW" -type f -name '*.js')

	# collectd.js 的 plugin enable 是變數 enabled，不是 o
	if ! grep -Fq 'statistics-plugin-enable-fix' "$COLLECTD_JS"; then
		sed -i "/enabled.modalonly = false;/a\\
			enabled.rmempty = false; // statistics-plugin-enable-fix\\
			enabled.retain = true;" "$COLLECTD_JS"
	fi

	# DynamicList 必須採用 UCI list，避免 RRATimespans 每次儲存都被刪除後重建
	if grep -Fq "option RRATimespans '2hour 1day 1week 1month 1year'" "$STAT_CONFIG"; then
		sed -i "s/^[[:space:]]*option RRATimespans '2hour 1day 1week 1month 1year'/	list RRATimespans '2hour'\\
	list RRATimespans '1day'\\
	list RRATimespans '1week'\\
	list RRATimespans '1month'\\
	list RRATimespans '1year'/" "$STAT_CONFIG"
	fi

	echo "luci-app-statistics save fix applied"
fi

include $(TOPDIR)/rules.mk

PKG_NAME:=yaxiang-core
PKG_VERSION:=0.2-dev
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/yaxiang-core
  SECTION:=yaxiang
  CATEGORY:=Yaxiang
  TITLE:=Yaxiang OS Core Service Framework
  DEPENDS:=+ubus +procd
endef

define Package/yaxiang-core/description
  Core service framework for Yaxiang OS.
  Provides system status collection, health monitoring, and log management.
  Uses procd for process management.
endef

define Build/Compile
endef

define Package/yaxiang-core/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/yaxiang-core $(1)/etc/init.d/yaxiang-core
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/usr/bin/yaxiang-collect $(1)/usr/bin/yaxiang-collect
	$(INSTALL_DIR) $(1)/usr/lib/yaxiang
	$(INSTALL_BIN) ./files/usr/lib/yaxiang/netctl.sh $(1)/usr/lib/yaxiang/netctl.sh
endef

$(eval $(call BuildPackage,yaxiang-core))

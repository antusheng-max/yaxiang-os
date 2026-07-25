include $(TOPDIR)/rules.mk

PKG_NAME:=yaxiang-console
PKG_VERSION:=0.2-dev
PKG_RELEASE:=1
PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/yaxiang-console
  SECTION:=yaxiang
  CATEGORY:=Yaxiang
  TITLE:=Yaxiang OS System Console
  DEPENDS:=+yaxiang-core
endef

define Package/yaxiang-console/description
  Local system console for Yaxiang OS.
  Provides menu-driven interface for system management via SSH/serial.
endef

define Build/Compile
endef

define Package/yaxiang-console/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/usr/bin/yaxiang-console $(1)/usr/bin/yaxiang-console
endef

$(eval $(call BuildPackage,yaxiang-console))

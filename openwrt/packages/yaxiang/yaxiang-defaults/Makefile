include $(TOPDIR)/rules.mk

PKG_NAME:=yaxiang-defaults
PKG_VERSION:=0.2-dev
PKG_RELEASE:=1
PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/yaxiang-defaults
  SECTION:=yaxiang
  CATEGORY:=Yaxiang
  TITLE:=Yaxiang OS First Boot Defaults
  DEPENDS:=+yaxiang-branding
endef

define Package/yaxiang-defaults/description
  First-boot configuration for Yaxiang OS.
  Sets hostname, LAN address, services, and security defaults.
endef

define Build/Compile
endef

define Package/yaxiang-defaults/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/etc/uci-defaults/10-yaxiang-setup $(1)/etc/uci-defaults/10-yaxiang-setup
endef

$(eval $(call BuildPackage,yaxiang-defaults))

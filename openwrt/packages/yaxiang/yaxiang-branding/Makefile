include $(TOPDIR)/rules.mk

PKG_NAME:=yaxiang-branding
PKG_VERSION:=0.2-dev
PKG_RELEASE:=1
PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/yaxiang-branding
  SECTION:=yaxiang
  CATEGORY:=Yaxiang
  TITLE:=Yaxiang OS Branding and Identity
endef

define Package/yaxiang-branding/description
  Yaxiang OS branding files including release info,
  console welcome message, and web brand resources.
endef

define Build/Compile
endef

define Package/yaxiang-branding/install
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DATA) ./files/etc/yaxiang-release $(1)/etc/yaxiang-release
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/etc/uci-defaults/99-yaxiang-branding $(1)/etc/uci-defaults/99-yaxiang-branding
	$(INSTALL_DIR) $(1)/www/brand
	$(CP) ./files/www/brand/* $(1)/www/brand/
endef

$(eval $(call BuildPackage,yaxiang-branding))

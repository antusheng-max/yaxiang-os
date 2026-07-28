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
  DEPENDS:=+yaxiang-branding +uhttpd +px5g-mbedtls +jsonfilter
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
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/yaxiang-security-gate $(1)/etc/init.d/yaxiang-security-gate
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/usr/sbin/yaxiang-security-gate-apply $(1)/usr/sbin/yaxiang-security-gate-apply
	$(INSTALL_BIN) ./files/usr/sbin/yaxiang-enable-management $(1)/usr/sbin/yaxiang-enable-management
	$(INSTALL_DIR) $(1)/www-init/cgi-bin
	$(INSTALL_DATA) ./files/www-init/index.html $(1)/www-init/index.html
	$(INSTALL_BIN) ./files/www-init/cgi-bin/yaxiang-initialize $(1)/www-init/cgi-bin/yaxiang-initialize
endef

$(eval $(call BuildPackage,yaxiang-defaults))

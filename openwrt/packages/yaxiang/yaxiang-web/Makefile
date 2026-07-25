include $(TOPDIR)/rules.mk

PKG_NAME:=yaxiang-web
PKG_VERSION:=0.2-dev
PKG_RELEASE:=1
PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/yaxiang-web
  SECTION:=yaxiang
  CATEGORY:=Yaxiang
  TITLE:=Yaxiang OS Web Administration Interface
  DEPENDS:=+uhttpd
endef

define Package/yaxiang-web/description
  Yaxiang OS Web management interface.
  Installs production-built frontend to /www/.
endef

define Build/Compile
endef

define Package/yaxiang-web/install
	$(INSTALL_DIR) $(1)/www
	$(CP) ./files/www/* $(1)/www/
endef

$(eval $(call BuildPackage,yaxiang-web))

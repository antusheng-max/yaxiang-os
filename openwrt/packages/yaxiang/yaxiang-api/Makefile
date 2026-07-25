include $(TOPDIR)/rules.mk

PKG_NAME:=yaxiang-api
PKG_VERSION:=0.2-dev
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/yaxiang-api
  SECTION:=yaxiang
  CATEGORY:=Yaxiang
  TITLE:=Yaxiang OS Read-only System API
  DEPENDS:=+ubus +rpcd +rpcd-mod-uci +yaxiang-core
endef

define Package/yaxiang-api/description
  Read-only API endpoints for Yaxiang OS web interface.
  Provides system info, network status, and line status via ubus/rpcd.
endef

define Build/Compile
endef

define Package/yaxiang-api/install
	$(INSTALL_DIR) $(1)/usr/libexec/rpcd
	$(INSTALL_BIN) ./files/usr/libexec/rpcd/yaxiang_system $(1)/usr/libexec/rpcd/yaxiang_system
	$(INSTALL_BIN) ./files/usr/libexec/rpcd/yaxiang_network $(1)/usr/libexec/rpcd/yaxiang_network
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./files/usr/share/rpcd/acl.d/yaxiang.json $(1)/usr/share/rpcd/acl.d/yaxiang.json
endef

$(eval $(call BuildPackage,yaxiang-api))

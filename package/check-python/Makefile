include $(TOPDIR)/rules.mk

PKG_NAME:=check-python
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/check-python
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Check Python 3.9 version
  DEPENDS:=+libc
endef

define Package/check-python/description
 A mock userspace utility that checks Python 3.9 version and writes log output.
endef

define Build/Prepare
	$(INSTALL_DIR) $(PKG_BUILD_DIR)
	$(CP) ./src/check_python.c $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) -static -o $(PKG_BUILD_DIR)/check_python $(PKG_BUILD_DIR)/check_python.c
endef

define Package/check-python/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/check_python $(1)/usr/bin/check_python
endef

$(eval $(call BuildPackage,check-python))

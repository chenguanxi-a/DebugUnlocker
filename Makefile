# DebugUnlocker Makefile
# 编译：make package (生成 .deb) 或 make (仅生成 .dylib)
# GitHub Actions 会自动运行 make package 并提取 .dylib

export THEOS_DEVICE_IP = 
export TARGET = iphone:clang:latest:14.0
export ARCHS = arm64 arm64e
export DEBUG = 0
export FINALPACKAGE = 1

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DebugUnlocker
DebugUnlocker_FILES = Tweak.xm
DebugUnlocker_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable
DebugUnlocker_FRAMEWORKS = UIKit Foundation

include $(THEOS)/makefiles/tweak.mk

# 额外：把 .dylib 单独拷出来方便 GitHub Actions 打包
after-package::
	@mkdir -p $(THEOS_PROJECT_DIR)/artifacts
	@cp -f $(THEOS_OBJ_DIR)/debug/*.dylib $(THEOS_PROJECT_DIR)/artifacts/DebugUnlocker.dylib 2>/dev/null || true
	@cp -f $(THEOS_OBJ_DIR)/arm64/*.dylib $(THEOS_PROJECT_DIR)/artifacts/DebugUnlocker.dylib 2>/dev/null || true
	@find $(THEOS_OBJ_DIR) -name "*.dylib" -exec cp -f {} $(THEOS_PROJECT_DIR)/artifacts/DebugUnlocker.dylib \; 2>/dev/null || true
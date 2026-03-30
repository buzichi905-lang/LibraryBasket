TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LibraryBasket

LibraryBasket_FILES = Tweak.xm \
	BHLibraryBasketStore.m \
	BHLibraryBasketController.m
LibraryBasket_CFLAGS = -fobjc-arc
LibraryBasket_FRAMEWORKS = UIKit Foundation CoreGraphics
LibraryBasket_PRIVATE_FRAMEWORKS = SpringBoardServices

include $(THEOS_MAKE_PATH)/tweak.mk

include $(THEOS)/makefiles/common.mk

THEOS_DEVICE_IP = 172.16.232.40
ARCHS = arm64
TWEAK_NAME = SearchForClubhouse
SearchForClubhouse_FILES = Tweak.xm
SearchForClubhouse_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 clubhouse"

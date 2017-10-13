# @Author: Dana Buehre <creaturesurvive>
# @Date:   18-09-2017 1:58:28
# @Email:  dbuehre@me.com
# @Filename: Makefile
# @Last modified by:   creaturesurvive
# @Last modified time: 24-09-2017 1:59:37
# @Copyright: Copyright © 2014-2017 CreatureSurvive


ARCHS = armv7 armv7s arm64
GO_EASY_ON_ME=1
TARGET = iphone:clang:latest:latest

FINALPACKAGE = 1
DEBUG = 0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PullToClear
PullToClear_FILES = $(wildcard *.m) $(wildcard *.xm)
PullToClear_FRAMEWORKS = UIKit QuartzCore CoreGraphics AudioToolbox
ADDITIONAL_OBJCFLAGS = -fobjc-arc
PullToClear_LDFLAGS += -lCSPreferencesProvider

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += preferences
include $(THEOS_MAKE_PATH)/aggregate.mk

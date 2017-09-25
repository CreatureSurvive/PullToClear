include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = PullToClear
PullToClear_FILES = PTCPreferenceController.m
PullToClear_INSTALL_PATH = /Library/PreferenceBundles
PullToClear_FRAMEWORKS = UIKit
PullToClear_PRIVATE_FRAMEWORKS = Preferences
PullToClear_CFLAGS += -fobjc-arc
PullToClear_LDFLAGS +=  -lCSPreferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/PullToClear.plist$(ECHO_END)

# To release run like
#   make BUILD=release
# to build in release mode. Make sure ant.properties contains
#   key.store=.../michalis.keystore
#   key.alias=michalis
# See http://developer.android.com/tools/publishing/app-signing.html

BUILD=debug

.PHONY: default
default: data
	cd ../../../castle_game_engine/ && ppcrossarm -Tandroid -CfVFPV3 -dRELEASE $${CASTLE_FPC_OPTIONS:-} @castle-fpc.cfg ../darkest_before_dawn/code/darkest_before_dawn.lpr
	mkdir -p libs/armeabi/
	cp -f ../libdarkest_before_dawn.so libs/armeabi/libdarkest_before_dawn.so
	ant $(BUILD)
#	adb uninstall net.sourceforge.castleengine.darkestbeforedawn
	adb install -r bin/DarkestBeforeDawn-$(BUILD).apk
	adb shell am start -a android.intent.action.MAIN -n net.sourceforge.castleengine.darkestbeforedawn/android.app.NativeActivity

.PHONY: clean
clean:
	rm -Rf bin/ gen/ libs/ obj/ assets/

# You only need to call it once
.PHONY: init
init:
	android update lib-project -p . --target 1

.PHONY: data
data:
	rm -Rf assets/
	cp -R ../../data/ assets/
	find assets/ -type f \
	   '(' -iname '*~' -or \
	       -iname '*.xcf' -or \
	       -iname '*.blend' -or \
	       -iname '*.blend1' -or \
	       -iname '*.blend2' ')' \
	   -exec rm -f '{}' ';'

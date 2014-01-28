.PHONY: standalone
standalone:
	cd ../castle_game_engine/ && \
	  fpc -dRELEASE -dCASTLE_WINDOW_BEST_NOGUI @castle-fpc.cfg \
	  $${CASTLE_FPC_OPTIONS:-} \
	  ../darkest_before_dawn/code/darkest_before_dawn_standalone.lpr
	mv code/darkest_before_dawn_standalone .

.PHONY: clean
clean:
	rm -f darkest_before_dawn_standalone darkest_before_dawn_standalone.exe \
	  code/libdarkest_before_dawn.so
	find data/ -iname '*~' -exec rm -f '{}' ';'
	$(MAKE) -C ../castle_game_engine/ clean
	$(MAKE) -C code/android clean

FILES := --exclude *.xcf --exclude '*.blend*' README.txt data/
WINDOWS_FILES := $(FILES) darkest_before_dawn_standalone.exe *.dll
UNIX_FILES    := $(FILES) darkest_before_dawn_standalone

.PHONY: release-win32
release-win32: clean standalone
	rm -Rf darkest_before_dawn-win32.zip
	zip -r darkest_before_dawn-win32.zip $(WINDOWS_FILES)

.PHONY: release-linux
release-linux: clean standalone
	rm -Rf darkest_before_dawn-linux-i386.tar.gz
	tar czvf darkest_before_dawn-linux-i386.tar.gz $(UNIX_FILES)

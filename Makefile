# Extension of executable is determined by target operating system,
# that in turn depends on 1. -T options in CASTLE_FPC_OPTIONS and
# 2. current OS, if no -T inside CASTLE_FPC_OPTIONS. It's easiest to just
# use "fpc -iTO", to avoid having to detect OS (or parse CASTLE_FPC_OPTIONS)
# in the Makefile.
TARGET_OS = $(shell fpc -iTO $${CASTLE_FPC_OPTIONS:-})
EXE_EXTENSION = $(shell if '[' '(' $(TARGET_OS) '=' 'win32' ')' -o '(' $(TARGET_OS) '=' 'win64' ')' ']'; then echo '.exe'; else echo ''; fi)

.PHONY: standalone
standalone:
	cd ../castle_game_engine/ && \
	  fpc -dRELEASE -dCASTLE_WINDOW_BEST_NOGUI @castle-fpc.cfg \
	  $${CASTLE_FPC_OPTIONS:-} \
	  ../darkest_before_dawn/code/darkest_before_dawn_standalone.lpr
	mv code/darkest_before_dawn_standalone$(EXE_EXTENSION) .

.PHONY: clean
clean:
	rm -f \
	       darkest_before_dawn_standalone      darkest_before_dawn_standalone.exe \
	  code/darkest_before_dawn_standalone code/darkest_before_dawn_standalone.exe \
	  code/libdarkest_before_dawn.so
	find data/ -iname '*~' -exec rm -f '{}' ';'
	$(MAKE) -C ../castle_game_engine/ clean
	$(MAKE) -C android clean

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

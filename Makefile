.PHONY: standalone
standalone:
	cd ../castle_game_engine/ && fpc -dRELEASE @castle-fpc.cfg \
	  ../darkest_before_dawn/code/darkest_before_dawn_standalone.lpr
	mv code/darkest_before_dawn_standalone .

.PHONY: clean
clean:
	rm -f darkest_before_dawn_standalone code/libdarkest_before_dawn.so
	$(MAKE) -C ../castle_game_engine/ clean
	$(MAKE) -C code/android clean


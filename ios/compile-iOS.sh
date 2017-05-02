#!/bin/bash
set -e

castle-engine compile --target=ios
mv -f ../code/libdarkest_before_dawn_ios.a libiosappglue.a

#copy resources from data to assets while removing the source files
echo "Copying assets"
rm -Rf Darkest/data/
cp -R ../data/ Darkest/data/
find Darkest/data/ -type f \
   '(' -iname '*~' -or \
	   -iname '*.xcf' -or \
	   -iname '*.blend' -or \
	   -iname '*.blend1' -or \
	   -iname '*.blend2' ')' \
   -exec rm -f '{}' ';'

#!/bin/bash

DIRNAME=`dirname "$0"`
BUILDER="$DIRNAME/builder"
. "$BUILDER/build_env.sh"


clear_build_directory

clear_build_repository


wget -O "$MAPS_DIRECTORY/core.git.map" "https://raw.github.com/dylan171/cs-studio/alt-build-system/core/core.git.map"
if [ $? != 0 ]; then
	echo "Error downloading 'core.git.map'. Aborting."
	exit 1
fi

wget -O "$MAPS_DIRECTORY/rap-runtime.p2.map" "https://raw.github.com/dylan171/cs-studio/alt-build-system/core/rap-runtime-1.4.2-R-20120213-1324.p2.map"
if [ $? != 0 ]; then
	echo "Error downloading 'rap-runtime-1.4.2-R-20120213-1324.p2.map'. Aborting."
	exit 1
fi

wget -O "$MAPS_DIRECTORY/apps.git.map" "https://raw.github.com/dylan171/cs-studio/alt-build-system/applications/applications.git.map"
if [ $? != 0 ]; then
	echo "Error downloading 'applications.git.map'. Aborting."
	exit 1
fi

build_feature "org.csstudio.core.build.feature"
if [ $? != 0 ]; then
	echo "Error building: org.csstudio.core.build.feature"
	exit 1
fi

generate_map_p2 "cs-studio.p2.map"

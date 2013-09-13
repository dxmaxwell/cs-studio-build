#!/bin/bash

DIRNAME=`dirname "$0"`
BUILDER="$DIRNAME/builder"
. "$BUILDER/build_env.sh"


clear_build_directory



wget -O "$MAPS_DIRECTORY/orbit.p2.map" "http://download.eclipse.org/tools/orbit/downloads/drops/R20130827064939/orbitBundles-R20130827064939.p2.map"
if [ $? != 0 ]; then
	echo "Error downloading 'orbitBundles-R20130827064939.p2.map'. Aborting."
	exit 1
fi

if [ -f "$BUILD_REPOSITORY/cs-studio.p2.map" ]; then
	# If 'core' has already be build then use it instead for building applications.
	cp  -f "$BUILD_REPOSITORY/cs-studio.p2.map" "$MAPS_DIRECTORY"
else
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
fi


wget -O "$MAPS_DIRECTORY/apps.git.map" "https://raw.github.com/dylan171/cs-studio/alt-build-system/applications/applications.git.map"
if [ $? != 0 ]; then
	echo "Error downloading 'applications.git.map'. Aborting."
	exit 1
fi

build_feature "org.csstudio.applications.build.feature"
if [ $? != 0 ]; then
	echo "Error building: org.csstudio.core.build.feature"
	exit 1
fi

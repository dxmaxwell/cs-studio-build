#!/bin/bash

BUILDER=`dirname "$0"`
. "$BUILDER/util/build-functions.sh"


clear_build_directory

clear_build_repository


cp -f $BUILDER/maps/*.map "$MAPS_DIRECTORY"


build_feature "org.csstudio.core.build.feature"
if [ $? != 0 ]; then
	echo "Error building: org.csstudio.core.build.feature"
	exit 1
fi

# generate_map_p2 "cs-studio.p2.map"

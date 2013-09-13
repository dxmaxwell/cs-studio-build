
echo "Preparing the build environment."
echo

CURDIR="$PWD"

if [ -z "$BUILDER" ]; then
    BUILDER="$CURDIR"
fi

if [ ! -d "$BUILDER" ]; then
    echo "Error: Builder directory not found: $BUILDER"
    exit 1
fi

# Find absolute directory.
cd "$BUILDER"
BUILDER="$PWD"
cd "$CURDIR"


if [ ! -f "$BUILDER/build.properties" ]; then
    echo "Error: Build properties file not found: $BUILDER/build.properties"
    exit 1
fi

if [ -z "$QUALIFIER" ]; then
    QUALIFIER=`date +"%Y%m%d%H%M%S"`
fi


# The value of BASE_LOCATION should match the 'baseLocation' property in build.properties.
BASE_LOCATION="$BUILDER/ext/eclipse"

if [ ! -d "$BASE_LOCATION" ]; then
    echo "Eclipse target with Deltapack and GitFetchFactory NOT found."
    mkdir -p "$BUILDER/ext"
    cd "$BUILDER/ext"
    if [[ ! -f eclipse-rcp-indigo-SR2-linux-gtk.tar.gz ]]; then
        wget http://download.eclipse.org/technology/epp/downloads/release/indigo/SR2/eclipse-rcp-indigo-SR2-linux-gtk.tar.gz
    fi
    if [[ ! -f eclipse-3.7.2-delta-pack.zip ]]; then
        wget http://archive.eclipse.org/eclipse/downloads/drops/R-3.7.2-201202080800/eclipse-3.7.2-delta-pack.zip
    fi
    if [[ ! -f org.eclipse.egit.fetchfactory_0.12.0.201108111757.jar ]]; then
        http://download.eclipse.org/egit/pde/updates-nightly/plugins/org.eclipse.egit.fetchfactory_0.12.0.201108111757.jar
    fi
    tar -xzvf eclipse-rcp-indigo-SR2-linux-gtk.tar.gz
    unzip -o eclipse-3.7.2-delta-pack.zip
    cp -f org.eclipse.egit.fetchfactory_0.12.0.201108111757.jar eclipse/plugins
    cd "$CURDIR"
fi


# The value of CLONE_DIRECTORY should match the 'fetchCacheLocation' property in build.properties.
CLONE_DIRECTORY="$BUILDER/ext/clones"
mkdir -p "$CLONE_DIRECTORY"


# The value of BUILD_DIRECTORY should match the 'buildDirectory' and 'transformedRepoLocation' properties in build.properties.
BUILD_DIRECTORY="$BUILDER/buildDirectory"
mkdir -p "$BUILD_DIRECTORY"

MAPS_DIRECTORY="$BUILD_DIRECTORY/maps"
mkdir -p "$MAPS_DIRECTORY"


# The value of BUILD_REPOSITORY should match the 'p2.build.repo' property in build.properties.
BUILD_REPOSITORY="$BUILDER/buildRepository"
mkdir -p "$BUILD_REPOSITORY"


function clear_build_directory {
    echo "Clearing build directory: $BUILD_DIRECTORY"
    echo
    if [ -e "$BUILD_DIRECTORY" ]; then
        rm -rf "$BUILD_DIRECTORY"
    fi
    mkdir -p "$BUILD_DIRECTORY"
    if [ -e "$MAPS_DIRECTORY" ]; then
        rm -rf "$MAPS_DIRECTORY"
    fi
    mkdir -p "$MAPS_DIRECTORY"
}


function clear_build_repository {
    echo "Clearing build repository: $BUILD_REPOSITORY"
    echo
    if [ -e "$BUILD_REPOSITORY" ]; then
        rm -rf "$BUILD_REPOSITORY"
    fi
    mkdir -p "$BUILD_REPOSITORY"
}


function build_feature {
    echo "Building feature: $1"
    echo
    java -jar $BASE_LOCATION/plugins/org.eclipse.equinox.launcher_*.jar \
        -application "org.eclipse.ant.core.antRunner" \
        -buildfile $BASE_LOCATION/plugins/org.eclipse.pde.build_*/scripts/build.xml \
        -DforceContextQualifier="$QUALIFIER" \
        -DtopLevelElementId="$1" \
        -Dbuilder="$BUILDER"
    return $?
}


function publish_artifacts {
    echo "Publishing build repository: $1"
    echo
    java -jar $BASE_LOCATION/plugins/org.eclipse.equinox.launcher_*.jar \
        -application "org.eclipse.equinox.p2.publisher.FeaturesAndBundlesPublisher" \
        -metadataRepository "$1" \
        -artifactRepository "$1" \
        -source "$BUILD_REPOSITORY" \
        -publishArtifacts -compress
    return $?
}

function generate_map_p2 {
    echo "Generating p2 map file: $BUILD_REPOSITORY/$1"
    echo
    "$BUILDER/util/generate-map.py" "--format=p2" "$BUILD_REPOSITORY/features" "$BUILD_REPOSITORY/plugins" --repo="${2-file:/$BUILD_REPOSITORY}"  > "$BUILD_REPOSITORY/$1"
    return $?
}

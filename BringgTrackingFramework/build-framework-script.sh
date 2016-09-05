#!/bin/sh

set -e
set +u

# Options

REVEAL_ARCHIVE_IN_FINDER=true

FRAMEWORK_NAME="${PROJECT_NAME}"

SIMULATOR_LIBRARY_PATH="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${FRAMEWORK_NAME}.framework"

DEVICE_LIBRARY_PATH="${BUILD_DIR}/${CONFIGURATION}-iphoneos/${FRAMEWORK_NAME}.framework"

UNIVERSAL_LIBRARY_DIR="${BUILD_DIR}/${CONFIGURATION}-iphoneuniversal"

FRAMEWORK="${UNIVERSAL_LIBRARY_DIR}/${FRAMEWORK_NAME}.framework"

OUTPUT_DIR="${PROJECT_DIR}/Output/${FRAMEWORK_NAME}-${CONFIGURATION}-iphoneuniversal/"

# Avoid recursively calling this script.
if [[ $SF_MASTER_SCRIPT_RUNNING ]]
then
exit 0
fi
set -u
export SF_MASTER_SCRIPT_RUNNING=1

# Take build target
if [[ "$SDK_NAME" =~ ([A-Za-z]+) ]]
then
SF_SDK_PLATFORM=${BASH_REMATCH[1]}
else
echo "Could not find platform name from SDK_NAME: $SDK_NAME"
exit 1
fi

if [[ "$SF_SDK_PLATFORM" = "iphoneos" ]]
then
echo "Please choose iPhone simulator as the build target."
exit 1
fi

# Build the other (non-simulator) platform
xcodebuild -workspace ${FRAMEWORK_NAME}.xcworkspace -scheme ${FRAMEWORK_NAME}-iOS -sdk iphonesimulator -configuration ${CONFIGURATION} clean build CONFIGURATION_BUILD_DIR=${BUILD_DIR}/${CONFIGURATION}-iphonesimulator 2>&1

xcodebuild -workspace ${FRAMEWORK_NAME}.xcworkspace -scheme ${FRAMEWORK_NAME}-iOS -sdk iphoneos -configuration ${CONFIGURATION} clean build CONFIGURATION_BUILD_DIR=${BUILD_DIR}/${CONFIGURATION}-iphoneos 2>&1

# Copy the framework structure to the universal folder (clean it first)
rm -rf "${UNIVERSAL_LIBRARY_DIR}"
mkdir -p "${UNIVERSAL_LIBRARY_DIR}"
cp -R "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${FRAMEWORK_NAME}.framework" "${UNIVERSAL_LIBRARY_DIR}/${FRAMEWORK_NAME}.framework"

# Smash them together to combine all architectures
lipo -create "${SIMULATOR_LIBRARY_PATH}/${FRAMEWORK_NAME}" "${DEVICE_LIBRARY_PATH}/${FRAMEWORK_NAME}" -output "${FRAMEWORK}/${FRAMEWORK_NAME}"

# On Release, copy the result to release directory

OUTPUT_DIR="${PROJECT_DIR}/Output/${FRAMEWORK_NAME}-${CONFIGURATION}-iphoneuniversal/"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

cp -r "${FRAMEWORK}" "$OUTPUT_DIR"

if [ ${REVEAL_ARCHIVE_IN_FINDER} = true ]; then
  open "${OUTPUT_DIR}/"
fi

# Remove Frameworks folder inside the .framework file
rm -rf "${OUTPUT_DIR}/${FRAMEWORK_NAME}.framework/Frameworks"

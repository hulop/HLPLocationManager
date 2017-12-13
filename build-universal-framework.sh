#!/bin/sh

FRAMEWORK_NAME="${PROJECT_NAME}"
SIMULATOR_LIBRARY_PATH="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${FRAMEWORK_NAME}.framework"
DEVICE_LIBRARY_PATH="${BUILD_DIR}/${CONFIGURATION}-iphoneos/${FRAMEWORK_NAME}.framework"
MAC_LIBRARY_PATH="${BUILD_DIR}/${CONFIGURATION}-macosx/${FRAMEWORK_NAME}.framework"
UNIVERSAL_LIBRARY_DIR="${BUILD_DIR}/${CONFIGURATION}-iphoneuniversal"
FRAMEWORK="${UNIVERSAL_LIBRARY_DIR}/${FRAMEWORK_NAME}.framework"

xcodebuild -workspace "${FRAMEWORK_NAME}.xcworkspace" -scheme "${FRAMEWORK_NAME}-iOS" -sdk iphonesimulator -configuration "${CONFIGURATION}" clean build CONFIGURATION_BUILD_DIR="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator" 2>&1
xcodebuild -workspace "${FRAMEWORK_NAME}.xcworkspace" -scheme "${FRAMEWORK_NAME}-iOS" -sdk iphoneos -configuration "${CONFIGURATION}" clean build CONFIGURATION_BUILD_DIR="${BUILD_DIR}/${CONFIGURATION}-iphoneos" 2>&1

rm -rf "${UNIVERSAL_LIBRARY_DIR}"
mkdir -p "${UNIVERSAL_LIBRARY_DIR}"

cp -R "${DEVICE_LIBRARY_PATH}" "${UNIVERSAL_LIBRARY_DIR}"

lipo -create -output "${FRAMEWORK}/${FRAMEWORK_NAME}" "${SIMULATOR_LIBRARY_PATH}/${FRAMEWORK_NAME}" "${DEVICE_LIBRARY_PATH}/${FRAMEWORK_NAME}"

mkdir -p "${PROJECT_DIR}/build/Carthage/Build/iOS"
rm -rf "${PROJECT_DIR}/build/Carthage/Build/iOS/${FRAMEWORK_NAME}.framework"
cp -R "${FRAMEWORK}" "${PROJECT_DIR}/build/Carthage/Build/iOS/"
#cp -R "${DEVICE_LIBRARY_PATH}" "${PROJECT_DIR}/build/Carthage/Build/iOS/"


xcodebuild -project "${FRAMEWORK_NAME}.xcodeproj" -scheme "${FRAMEWORK_NAME}-macOS" -sdk macosx -configuration "${CONFIGURATION}" clean build CONFIGURATION_BUILD_DIR="${BUILD_DIR}/${CONFIGURATION}-macosx" 2>&1

mkdir -p "${PROJECT_DIR}/build/Carthage/Build/Mac"
rm -rf "${PROJECT_DIR}/build/Carthage/Build/Mac/${FRAMEWORK_NAME}.framework"
cp -R "${MAC_LIBRARY_PATH}" "${PROJECT_DIR}/build/Carthage/Build/Mac/"

cd "${PROJECT_DIR}/build/"
zip -r "${FRAMEWORK_NAME}.framework.zip" Carthage

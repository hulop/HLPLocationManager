#!/bin/sh

project=HLPLocationManager

if [ $# -eq 0 ]
then
    CONFIG="Release"
elif [ $1 = "Release" -o $1 = "Debug" ]
then
    CONFIG=$1
elif [ $1 = "clean" ]
then
    xcodebuild clean -workspace ${project}.xcworkspace -scheme ${project}-iOS -sdk iphonesimulator
    xcodebuild clean -workspace ${project}.xcworkspace -scheme ${project}-iOS -sdk iphoneos
    xcodebuild clean -workspace ${project}.xcworkspace -scheme ${project}-macOS -sdk iphoneos
    rm -rf archives
    rm -rf ${project}.xcframework
    rm -rf ${project}.xcframework.zip
    exit 1
else
    echo "unknown configuration" $1
    exit 1
fi

CONFIG="$CONFIG -workspace ${project}.xcworkspace SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES only_active_arch=no defines_module=yes -quiet"

xcodebuild archive -configuration $CONFIG -scheme ${project}-iOS -sdk iphonesimulator -arch arm64 -arch x86_64 -archivePath "archives/${project}-iOS-Simulator" && \
xcodebuild archive -configuration $CONFIG -scheme ${project}-iOS -sdk iphoneos        -arch arm64 -arch armv7  -archivePath "archives/${project}-iOS" #&& \
xcodebuild archive -configuration $CONFIG -scheme ${project}-macOS -sdk macosx        -arch arm64 -arch x86_64 -archivePath "archives/${project}-macOS" #&& \
xcodebuild -create-xcframework \
	   -framework "./archives/${project}-iOS-Simulator.xcarchive/Products/Library/Frameworks/${project}.framework" \
	   -framework "./archives/${project}-iOS.xcarchive/Products/Library/Frameworks/${project}.framework" \
	   -framework "./archives/${project}-macOS.xcarchive/Products/Library/Frameworks/${project}.framework" \
	   -output "./${project}.xcframework"

rm -r HLPLocationManager.xcframework/*/HLPLocationManager.framework/Frameworks

rm ${project}.xcframework.zip
zip -r ${project}.xcframework.zip ${project}.xcframework

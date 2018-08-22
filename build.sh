#!/bin/sh

if [ $# -eq 0 ]
then
  CONFIG="Release"
elif [ $1 = "Release" -o $1 = "Debug" ]
then
  CONFIG=$1
elif [ $1 = "clean" ]
then
  xcodebuild clean -workspace HLPLocationManager.xcworkspace -scheme HLPLocationManager-iOS
  xcodebuild clean -workspace HLPLocationManager.xcworkspace -scheme HLPLocationManager-universal
  exit 0
else
  echo "unknown configuration" $1
  exit 1
fi

echo "Building HLPLocationManager with $CONFIG configuration"

xcodebuild -configuration $CONFIG -workspace HLPLocationManager.xcworkspace -scheme HLPLocationManager-iOS -sdk iphoneos
xcodebuild -configuration $CONFIG -workspace HLPLocationManager.xcworkspace -scheme HLPLocationManager-iOS -sdk iphonesimulator
xcodebuild -configuration $CONFIG -workspace HLPLocationManager.xcworkspace -scheme HLPLocationManager-universal

FRAMEWORK=BringgTracking
TARGET=BringgTracking-iOS

BUILD=build
FRAMEWORK_PATH=$FRAMEWORK.framework

#rm -Rf $BUILD
rm -f $FRAMEWORK_PATH.tar.gz

#xcodebuild archive -project $FRAMEWORK.xcodeproj -scheme $TARGET -sdk iphoneos SYMROOT=$BUILD
#xcodebuild build -project $FRAMEWORK.xcodeproj -target $TARGET -sdk iphonesimulator SYMROOT=$BUILD

cp -RL $BUILD/Release-iphoneos $BUILD/Release-universal

lipo -create $BUILD/Release-iphoneos/$FRAMEWORK_PATH/$FRAMEWORK $BUILD/Release-iphonesimulator/$FRAMEWORK_PATH/$FRAMEWORK -output $BUILD/Release-universal/$FRAMEWORK_PATH/$FRAMEWORK

tar -czv -C $BUILD/Release-universal -f $TARGET.framework.tar.gz $FRAMEWORK_PATH



#!/bin/zsh

# TODO: make this use reasonable paths

set -eux

declare DEVICE_IP="localhost"
declare DEVICE_PORT="2222"
declare NAME="Clutch"
declare ENTITLEMENTS="Resources/Clutch.entitlements"
declare EXECUTABLE_PATH=".build/debug/Clutch"

swift build

install_name_tool -change /System/Library/Frameworks/Foundation.framework/Versions/C/Foundation /System/Library/Frameworks/Foundation.framework/Foundation "$EXECUTABLE_PATH"
install_name_tool -change /System/Library/Frameworks/CoreServices.framework/Versions/A/CoreServices /System/Library/Frameworks/MobileCoreServices.framework/MobileCoreServices "$EXECUTABLE_PATH"
install_name_tool -change /System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation "$EXECUTABLE_PATH"

scp -P "$DEVICE_PORT" "$EXECUTABLE_PATH" root@"$DEVICE_IP":/usr/bin/"$NAME"
scp -P "$DEVICE_PORT" "$ENTITLEMENTS" root@"$DEVICE_IP":~/

ssh -p "$DEVICE_PORT" root@"$DEVICE_IP" chmod +x /usr/bin/"$NAME"
ssh -p "$DEVICE_PORT" root@"$DEVICE_IP" ldid -S/var/root/Clutch.entitlements /usr/bin/"$NAME"
ssh -p "$DEVICE_PORT" root@"$DEVICE_IP" rm -f /var/root/Clutch.entitlements

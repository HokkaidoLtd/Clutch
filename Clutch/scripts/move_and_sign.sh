#!/bin/zsh

# create DEVICE_IP and DEVICE_PORT variables in the target build settings

set -x
#export DEVICE_IP="192.168.178.70"
#export DEVICE_PORT="22"
echo "Using device ip: $DEVICE_IP"

cd "$PROJECT_DIR"

NAME=Clutch

! [ -d build ] && mkdir build
cp "$BUILT_PRODUCTS_DIR/$EXECUTABLE_PATH" "build/"
# Copy over the debug symbols for that sweet sweet debugging
cp -r "$BUILT_PRODUCTS_DIR/$EXECUTABLE_NAME.app.dSYM" "build/"


if [[ "$CONFIGURATION" == "Debug" ]]; then
	scp -P "$DEVICE_PORT" "build/$EXECUTABLE_NAME" root@"$DEVICE_IP":/usr/bin/"$NAME"
	scp -P "$DEVICE_PORT" "Clutch/scripts/Clutch.entitlements" root@"$DEVICE_IP":~

	ssh -p "$DEVICE_PORT" root@"$DEVICE_IP" chmod +x /usr/bin/"$NAME"
	ssh -p "$DEVICE_PORT" root@"$DEVICE_IP" ldid -S/var/root/Clutch.entitlements /usr/bin/"$NAME"
	ssh -p "$DEVICE_PORT" root@"$DEVICE_IP" rm -f /var/root/Clutch.entitlements
fi

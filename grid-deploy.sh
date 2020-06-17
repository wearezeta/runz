#!/bin/bash

SYSPORT=8210
APPIUMPORT=4730
HUBPORT=4444
DEVICES=`for i in $(adb devices | egrep "device$" | cut -f1); do adb -s $i shell getprop ro.build.characteristics | grep -q -v tablet && echo -n "$i " ; done; true`

printf "[Node Setup]\n"
DEVICECOUNT=0
for ID in $DEVICES ; do
	((DEVICECOUNT++))
    ((SYSPORT++))
    ((APPIUMPORT++))
	
	MODEL=`adb -s $ID shell getprop ro.product.model | sed 's/\r//'`
    MANUFACTURER=`adb -s $ID shell getprop ro.product.manufacturer | sed 's/\r//'`
    NAME=`adb -s $ID shell getprop ro.product.name | sed 's/\r//'`
    OS=`adb -s $ID shell getprop ro.build.version.release | sed 's/\r//'`
    
    printf "\n\nDevice #%s:%s (Version[%s] Manufacturer[%s] Model[%s] Name[%s])\n" "$DEVICECOUNT" "$ID" "$OS" "$MANUFACTURER" "$MODEL" "$NAME"	
    
    printf "[Uninstalling appium software]\n"
    adb -s $ID uninstall io.appium.settings 2>/dev/null || printf "io.appium.settings not installed\n"
    adb -s $ID uninstall io.appium.uiautomator2.server 2>/dev/null || printf "io.appium.uiautomator2.server not installed\n"
    adb -s $ID uninstall io.appium.uiautomator2.server.test 2>/dev/null || printf "io.appium.uiautomator2.server.test not installed\n"
    
    NODEFILENAME=nodes/$ID-node.json
    printf "[Generating %s]\n" "$NODEFILENAME"
    
    cat <<EOF > $NODEFILENAME
{
  "capabilities":
  [
    {
      "platformName": "ANDROID",
      "browserName": "${MANUFACTURER}-${NAME}-${MODEL}-${ID}",
      "adbExecTimeout": 40000,
      "maxInstances": 1,
      "deviceName": "$ID",
      "version": "$OS",
      "systemPort": $SYSPORT
    }
  ],
  "configuration":
  {
    "proxy": "org.openqa.grid.selenium.proxy.DefaultRemoteProxy",
    "maxSession": 1,
    "register": true,
    "registerCycle": 5000,
    "hubPort": $HUBPORT,
    "hubHost": "127.0.0.1",
    "hubProtocol": "http"
  }
}

EOF

appium --relaxed-security -p $APPIUMPORT --nodeconfig $NODEFILENAME --log-timestamp --log-no-colors --default-capabilities '{"udid":"'$ID'","systemPort":'$SYSPORT'}' &
    
done
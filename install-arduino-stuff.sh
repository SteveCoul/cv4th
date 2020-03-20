#!/bin/sh
curl -O https://downloads.arduino.cc/arduino-1.8.12-macosx.zip
curl -O https://downloads.arduino.cc/arduino-cli/arduino-cli_0.9.0_macOS_64bit.tar.gz
rm -rf ~/Applications/Arduino.app
unzip arduino-1.8.12-macosx.zip -d ~/Applications
tar jxf arduino-cli_0.9.0_macOS_64bit.tar.gz -C ~/Applications/Arduino.app
~/Applications/Arduino.app/arduino-cli --additional-urls "https://raw.githubusercontent.com/sparkfun/Arduino_Boards/master/IDE_Board_Manager/package_sparkfun_index.json" core update-index
~/Applications/Arduino.app/arduino-cli --additional-urls "https://raw.githubusercontent.com/sparkfun/Arduino_Boards/master/IDE_Board_Manager/package_sparkfun_index.json" core install arduino:samd
~/Applications/Arduino.app/arduino-cli --additional-urls "https://raw.githubusercontent.com/sparkfun/Arduino_Boards/master/IDE_Board_Manager/package_sparkfun_index.json" core install SparkFun:samd


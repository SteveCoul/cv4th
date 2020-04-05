#!/bin/sh
rm -rf arm-tools
mkdir arm-tools 
cd arm-tools
git clone https://github.com/ARM-software/CMSIS_5.git
git clone https://github.com/arduino/ArduinoModule-CMSIS-Atmel.git
curl -L https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/gcc-arm-none-eabi-9-2019-q4-major-mac.tar.bz2 | tar jxv
curl -L https://github.com/shumatech/BOSSA/releases/download/1.9.1/bossa-1.9.1.dmg -O
hdiutil attach bossa-1.9.1.dmg 
cp /Volumes/BOSSA/bossac .
hdiutil detach /Volumes/BOSSA


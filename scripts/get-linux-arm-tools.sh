#!/bin/sh
rm -rf arm-tools
mkdir arm-tools 
cd arm-tools
git clone https://github.com/ARM-software/CMSIS_5.git
git clone https://github.com/arduino/ArduinoModule-CMSIS-Atmel.git
curl -L https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2 | tar jxv
sudo apt-get install bossa-cli



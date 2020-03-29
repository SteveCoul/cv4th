# cv4th
C Virtual Machine Forth

Linux/Mac host kernel builds are moderately portable just a thin
C virtual machine and little to no library support.

16/32bit forth on 16/32bit targets.

Arduino demonstration on a few targets so far:

esp8266:esp8266:d1
SparkFun:samd:samd51_thing_plus
SparkFun:samd:samd21_dev


Most arduino targets go via the filesystem layer into the Arduino
core for their functionality. ( like digitalIO etc ).

The samd51 things plus target is beginning to get it's own forth
implementations going direct to the hardware. Eventually I 
intend this build to go bare metal.


# Uploading binary from command line (esp8266 WeMos Mini)

/Users/stevencoul/Library/Arduino15/packages/esp8266/tools/python3/3.7.2-post1/python3 /Users/stevencoul/Library/Arduino15/packages/esp8266/hardware/esp8266/2.6.3/tools/upload.py --chip esp8266 --port /dev/cu.usbserial-20 --baud 921600 --before default_reset --after hard_reset write_flash 0x0 arduino/arduino.esp8266.esp8266.d1.bin 

## example - digital pins 

ext-wordlist dup get-order 1+ set-order set-current		\ open up the extended word list

PIN_D4 OUTPUT pinMode		\ configure LED pin for output

PIN_D4 LOW writeDigital		\ turn on (active low)

PIN_D4 HIGH writeDigital	\ turn off



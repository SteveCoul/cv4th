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


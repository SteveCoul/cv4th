all:
	make clean
	make TARGET=host
	make clean
	make TARGET=samd51 NO_UPLOAD=y
	make clean
	make TARGET=samd21 NO_UPLOAD=y
	make clean
	make TARGET=mini NO_UPLOAD=y
	make clean
	@echo " "
	@echo " "
	@echo " "
	@echo "All targets at least compiled"
	@echo " "
	@echo " "
	@echo " "


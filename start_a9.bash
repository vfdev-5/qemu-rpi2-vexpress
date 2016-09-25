#!/bin/bash


echo "---------------------------------------------------------------"
echo "---- This script starts a QEMU ARMv7 emulator with a given SD Card image"
echo "---- Usage : $ bash start.bash /path/to/image/file.img [--verbose]"
echo "---- Usage : $ bash start.bash /dev/sd* [--verbose]"
echo "---------------------------------------------------------------"

########################################################################## 
# Useful functions 
##########################################################################
function help(){
    echo ""
    echo "Usage : $ bash start.bash /path/to/image/file.img [--verbose]"
    echo "      : $ bash start.bash /dev/sd* [--verbose]"
    echo ""
    echo "Info : this script starts a armv7 emulator with a linux-4.4.1 kernel"
    echo "       and uses input .img file or /dev/sd* as sd card source."
    echo "Warning : system content of the input is modified in order to start up the emulator. When script is quit, this system modification is reversed back."
    echo ""
}

function handle_error() {
    echo "ERROR : $1"
    echo "!!! start.bash exits with errors !!!"
    exit 1
}

##########################################################################
# Script
##########################################################################


if [ -z "$1" ]; then
    echo "No argument supplied. "
	help
    exit 1
fi

CURRENT_PATH="$(pwd "$0")"
KERNEL_PATH="kernel-qemu-4.4.1-vexpress"
DTB_PATH="vexpress-v2p-ca9.dtb"
#DTB_PATH="vexpress-v2p-ca15_a7.dtb"

if [ -n "$1" ]; then

    input_path="$1"
    is_verbose=0
    if [ -n "$2" ] && [ "$2" == "--verbose" ]; then is_verbose=1; fi
    echo ""
    echo ""
    echo "- Start QEMU ARMv7 emulator on ${image_path}"
    echo ""
    echo ""
    
    if [ "$is_verbose" == 1 ]; then
        bash $CURRENT_PATH/tools/enable_emulation.bash $input_path 1
    else
        bash $CURRENT_PATH/tools/enable_emulation.bash $input_path 1 > /dev/null
    fi         
      
    # Start QEMU    
    if [ "$is_verbose" == 1 ]; then
        sudo qemu-system-arm -m 1024M -M vexpress-a9 -cpu cortex-a9 -kernel $KERNEL_PATH -no-reboot -dtb $DTB_PATH -sd $input_path -serial stdio -append "root=/dev/mmcblk0p2 rw rootfstype=ext4 console=ttyAMA0,15200 loglevel=8"
        #sudo qemu-system-arm -m 2048M -M vexpress-a15 -cpu cortex-a15 -kernel $KERNEL_PATH -no-reboot -dtb $DTB_PATH -sd $input_path -serial stdio -append "root=/dev/mmcblk0p2 rw rootfstype=ext4 console=ttyAMA0,15200 loglevel=8"
    else
        sudo qemu-system-arm -m 1024M -M vexpress-a9 -cpu cortex-a9 -kernel $KERNEL_PATH -no-reboot -dtb $DTB_PATH -sd $input_path -append "root=/dev/mmcblk0p2 rw rootfstype=ext4"
        #udo qemu-system-arm -m 2048M -M vexpress-a15 -cpu cortex-a15 -kernel $KERNEL_PATH -no-reboot -dtb $DTB_PATH -sd $input_path -append "root=/dev/mmcblk0p2 rw rootfstype=ext4"

    fi

    if [ "$is_verbose" == 1 ]; then
        bash $CURRENT_PATH/tools/enable_emulation.bash $input_path 0
    else
        bash $CURRENT_PATH/tools/enable_emulation.bash $input_path 0 > /dev/null
    fi         
        
fi


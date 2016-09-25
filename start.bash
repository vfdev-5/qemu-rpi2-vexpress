#!/bin/bash


echo "---------------------------------------------------------------"
echo "---- This script starts a QEMU ARMv7 emulator with a given SD Card image"
echo "---- Usage : $ sh start.sh /path/to/image/file.img [--verbose]"
echo "---- Usage : $ sh start.sh /dev/sd* [--verbose]"
echo "---------------------------------------------------------------"

########################################################################## 
# Useful functions 
##########################################################################
function help(){
    echo ""
    echo "Info : this script starts a armv7 emulator with a linux-4.4.1 kernel"
    echo "       and uses input .img file or /dev/sd* as sd card source."
    echo "Warning : system content of the input is modified in order to start up the emulator. When script is quit, this system modification is reversed back."
    echo ""
}

function handle_error() {
    echo $1
    echo "START.BASH exits with error"
    exit 1
}

function remove_mount_path(){
    mount_path=$1
    if [ -d "$mount_path" ]; then
        rm -R $mount_path
        if [ "$?" != "0" ]; then handle_error "Failed to remove mount folder"; fi
    fi
}

function mount_input(){
    input_path=$1
    echo "mount_input : $input_path"
    
    # Check if input is a device (not a .img file)
    if [ "${input_path:0:5}" == "/dev/" ]; then         
        # sd card
        echo "sudo mount $input_path $MOUNT_PATH"
        #sudo mount $input_path $MOUNT_PATH
        if [ "$?" != "0" ]; then handle_error "Failed to mount sd card device"; fi 
    else
        # image file :
    	offset="$(fdisk -l $input_path | grep -o -i -P 'img2\s+[0-9]+[^0-9]' | sed -r -e 's/img2 +//g')"
        echo "sudo mount -o loop,offset=$((512*$offset)) $input_path $MOUNT_PATH"
        #sudo mount -o loop,offset=$((512*$offset)) $input_path $MOUNT_PATH
        if [ "$?" != "0" ]; then handle_error "Failed to mount image file"; fi         
    fi
}

function umount_input(){
    echo "sudo umount $MOUNT_PATH"
    #sudo umount $MOUNT_PATH
    if [ "$?" != "0" ]; then handle_error "Failed to unmount the folder '$MOUNT_PATH'"; fi         
}

function to_emulation(){

    input_path=$1
    echo "to_emulation : $input_path"
    
    mkdir $MOUNT_PATH
    
    mount_input $input_path
                
    
    if [ ! -f $MOUNT_PATH/etc/ld.so.preload ]; then
        handle_error "File /etc/ld.so.preload does not exists"
    else
        echo ""
        echo " - Replace /etc/ld.so.preload > /etc/ld.so.preload.original"
        echo ""
        sudo cp $MOUNT_PATH/etc/ld.so.preload $MOUNT_PATH/etc/ld.so.preload.original
        sudo sed -i 's/^/#/g' $MOUNT_PATH/etc/ld.so.preload    
    fi

    echo ""
    echo " - Replace /etc/fstab > /etc/fstab.original"
    echo ""
    
    
    umount_input
}

function from_emulation(){

    input_path=$1
    echo "from_emulation : $input_path"

    mount_input $input_path

    echo ""
    echo " - Replace /etc/ld.so.preload.original > /etc/ld.so.preload"
    echo ""
       
    echo ""
    echo " - Replace /etc/fstab.original > /etc/fstab"
    echo ""


    umount_input
}

##########################################################################
# Script
##########################################################################


if [ -z "$1" ]; then
    echo "No argument supplied. "
	help
    exit 1
fi

KERNEL_PATH="kernel-qemu-4.4.1-vexpress"
DTB_PATH="vexpress-v2p-ca9.dtb"
MOUNT_PATH="_mnt"
remove_mount_path $MOUNT_PATH


if [ -n "$1" ]; then

    input_path="$1"
    is_verbose=0
    if [ -n "$2" ] && [ "$2" == "--verbose" ]; then is_verbose=1; fi
    echo ""
    echo ""
    echo "- Start QEMU ARMv7 emulator on ${image_path}"
    echo ""
    echo ""
      
    to_emulation $input_path        

    
#    if [ $is_verbose ]; then
#        qemu-system-arm -m 1024M -M vexpress-a9 -cpu cortex-a9 -kernel $KERNEL_PATH -no-reboot -dtb $DTB_PATH -sd $image_path -serial stdio -append "root=/dev/mmcblk0p2 rw rootfstype=ext4 console=ttyAMA0,15200 loglevel=8"
#    else
#        qemu-system-arm -m 1024M -M vexpress-a9 -cpu cortex-a9 -kernel $KERNEL_PATH -no-reboot -dtb $DTB_PATH -sd $image_path -append "root=/dev/mmcblk0p2 rw rootfstype=ext4"
#    fi

    #from_emulation $input_path
        
fi


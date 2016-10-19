#!/bin/bash


echo "---------------------------------------------------------------"
echo "---- This script to chroot to a given SD Card image"
echo "---- Usage : $ bash chroot-tool.bash /dev/sd*"
echo "---------------------------------------------------------------"

########################################################################## 
# Useful functions 
##########################################################################
function help(){
    echo ""
    echo "Usage : $ bash chroot-tool.bash /dev/sd*"
    echo ""
    echo "Info : this script mounts /dev/sd*2 from the input /dev/sd* and starts chroot."
    echo "Warning : system content of the input is modified in order to chroot. When script is quit, this system modification is reversed back. File /usr/bin/qemu-arm-static is copied to <mount>/usr/bin and all lines from etc/ld.so.preload are commented."
    echo ""
}

source func.bash

##########################################################################
# Script
##########################################################################


if [ -z "$1" ]; then
    echo "No argument supplied. "
	help
    exit 1
fi

current_path="`pwd`"
mount_path="_mnt"

if [ -n "$1" ]; then

    input_path="$1"
    #is_verbose=1
    #if [ -n "$2" ] && [ "$2" == "--no-verbose" ]; then is_verbose=0; fi
    echo ""
    echo ""
    echo "- chroot on ${image_path}"
    echo ""
    echo ""
        
    # Mount input         
    mount_input $input_path $mount_path
    
    # Modify input system
    # Comment /etc/ld.so.preload content
    fix_ld_so_preload $mount_path 1
    # Copy /usr/bin/qemu-arm-static to <mount>/usr/bin 
    
    
    if [ ! -f "/usr/bin/qemu-arm-static" ]; then 
        handle_error "File '/usr/bin/qemu-arm-static' is not found on your system. Install it using 'sudo apt-get install qemu-arm-static'" "chroot-tool"        
    fi
    if [ ! -d "$mount_path/usr/bin" ]; then 
        umount_input $mount_path
        handle_error "Mounted directory '$mount_path/usr/bin' is not found" "chroot-tool"         
    fi 
    echo "- Copy /usr/bin/qemu-arm-static to $mount_path/usr/bin"
    sudo cp /usr/bin/qemu-arm-static $mount_path/usr/bin
    
        
    cd $mount_path    
    
    sudo chroot . bin/bash; uname -a
    
    cd $current_path
    
    # Restore input system
    if [ ! -f "$mount_path/usr/bin/qemu-arm-static" ]; then 
        echo "WARN: 'qemu-arm-static' file copied before chroot is not found anymore on your input system."       
    fi
    sudo rm $mount_path/usr/bin/qemu-arm-static
    if [ "$?" != "0" ]; then echo "ERROR : Failed to remove '$mount_path/usr/bin/qemu-arm-static' file. Please, remove it manually!" "remove_mount_path"; fi
    
    fix_ld_so_preload $mount_path 0
    
    umount_input $mount_path 1
    
fi


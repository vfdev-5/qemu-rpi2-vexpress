#!/bin/bash


########################################################################## 
# Useful functions 
##########################################################################

function handle_error() {
    #
    # Method to handle errors: report and exit 
    # $1 : error text
    # $2 : script name/function which exits with error
    #
    echo "ERROR : $1"
    echo "!!! $2 exits with errors !!!"
    exit 1
}

function remove_mount_path() {
    #
    # Method to remove mount path
    # $1 : mount path
    #
    local _mount_path=$1
    if [ -d "$_mount_path" ]; then
        rm -R $_mount_path
        if [ "$?" != "0" ]; then handle_error "Failed to remove mount folder" "remove_mount_path"; fi
    fi
}

function mount_input() {
    #
    # Method to mount an input as /dev/sd* or /path/to/file.img
    #   By default function mounts /dev/sd*2 if input is /dev/sd*
    # $1 : input path
    # $2 : mount path where to mount input 
    #
    local _input_path=$1
    local _mount_path=$2
   
    echo "- Device path : '$_input_path'"
    
    # Check if input is a device (not a .img file)
    if [ "${_input_path:0:5}" == "/dev/" ]; then         
        
        # sd card
        echo "Input is a SD card"
        # check if partition /dev/sdX2 is mounted :
        local _ret=`mount | grep -wE ${_input_path}2 | awk '{ print $3 }'`

        if [ "$_ret" != "" ]; then
            echo "Currently SD is mounted on '$_ret'"
            # Unmount current location and remount in mine 
            sudo umount -l ${_input_path}2
            if [ "$?" != "0" ]; then handle_error "Failed to unmount the folder s'${_input_path}2'" "mount_input"; fi
        fi
       
        remove_mount_path $_mount_path
        mkdir $_mount_path

        # not mounted -> mount
        local _offset="$(sudo fdisk -l $_input_path | grep -o -i -P $_input_path'2\s+[0-9]+[^0-9]' | sed -r -e 's/'${_input_path//\//\\/}'2 +//g')"
        if [ "$_offset" == "" ]; then handle_error "Failed to find out the offset" "mount_input"; fi          
        sudo mount -o loop,offset=$((512*$_offset)) $_input_path $_mount_path
        if [ "$?" != "0" ]; then handle_error "Failed to mount image file" "mount_input"; fi 
    
    else

        mkdir $_mount_path
        # image file :
    	local _offset="$(sudo fdisk -l $_input_path | grep -o -i -P 'img2\s+[0-9]+[^0-9]' | sed -r -e 's/img2 +//g')"
        sudo mount -o loop,offset=$((512*$_offset)) $_input_path $MOUNT_PATH
        if [ "$?" != "0" ]; then handle_error "Failed to mount image file" "mount_input"; fi         
    fi
}

function umount_input(){
    #
    # Method to unmount path
    # $1 : input path to unmount
    # $2 : 0/1 if delete the path after unmount 
    # 

    local _input_path=$1
    echo "- Unmount path : '$_input_path'"

    sudo umount -l $_input_path
    if [ "$?" != "0" ]; then handle_error "Failed to unmount the folder '$_input_path'" "umount_input"; fi                 
    
    if [ -n "$2" ] && [ "$2" == "1" ]; then remove_mount_path $_input_path; fi
}



function fix_ld_so_preload() {

    #
    # Function to disable/backup <mount>/etc/ld.so.preload
    # $1 : mount_path
    # $2 : 1 - disable = Backup and comment line : /usr/lib/arm-.*/libarmem.so 
    #    : 0 - restore saved <mount>/etc/ld.so.preload      
    #    

    local _mount_path=$1
    local _value=$2
    
    if [ "$_value" == "1" ]; then
    
        if [ ! -f "$_mount_path/etc/ld.so.preload" ]; then
            umount_input $_mount_path 
            handle_error "File $_mount_path/etc/ld.so.preload does not exists" "fix_ld_so_preload"
        else
            if [ -f "$_mount_path/etc/ld.so.preload.original" ]; then
                echo "- System is already in emulation state"
            else
                echo ""
                echo " - Replace $_mount_path/etc/ld.so.preload > $_mount_path/etc/ld.so.preload.original"
                echo ""
                sudo cp $_mount_path/etc/ld.so.preload $_mount_path/etc/ld.so.preload.original
                # Check if the line to comment exists : /usr/lib/arm-*/libarmmem.so                  
                sudo sed -i '/\/usr\/lib\/arm-.*\/libarmmem.so/ s/^/#/' $_mount_path/etc/ld.so.preload
            fi
        fi
        
    elif [ "$_value" == "0" ]; then
    
        if [ ! -f "$_mount_path/etc/ld.so.preload.original" ]; then
            echo "- System is already in its original state"
        else
            echo ""
            echo " - Replace $_mount_path/etc/ld.so.preload.original > $_mount_path/etc/ld.so.preload"
            echo ""
            sudo rm $_mount_path/etc/ld.so.preload
            sudo mv $_mount_path/etc/ld.so.preload.original $_mount_path/etc/ld.so.preload
        fi

    fi
}




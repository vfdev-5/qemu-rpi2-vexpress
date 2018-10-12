#!/bin/bash


echo "---------------------------------------------------------------"
echo "---- This script modifies system to enable QEMU emulation "
echo "---- Usage : $ bash enable_emulation.bash /path/to/image/file.img value"
echo "---- Usage : $ bash enable_emulation.bash /dev/sd* value"
echo "---------------------------------------------------------------"

########################################################################## 
# Useful functions 
##########################################################################
function help(){
    echo ""
    echo " Usage : $ bash enable_emulation.bash /path/to/image/file.img value"
    echo "       : $ bash enable_emulation.bash /dev/sd* value"
    echo ""
    echo "value = 0 <-> false <-> restore to original state "
    echo "      = 1 <-> true <-> enable emulation "
    echo ""
    echo "Info : this script mounts and modifies the linux system files to enable QEMU emulation or restore to the original state"
    echo ""
    echo "Modifications are : "
    echo "/etc/ld.so.preload : comment all lines"
    echo "/etc/fstab : comment default mount configuration"
    echo ""
    echo "see for more details : "
    echo "http://stackoverflow.com/questions/38837606/emulate-raspberry-pi-raspbian-with-qemu/39676138"
}

function handle_error() {
    remove_mount_path $MOUNT_PATH
    echo "ERROR : $1"
    echo "!!! enable_emulation.bash exits with errors !!!"
    exit 1
}

function remove_mount_path(){
    local _mount_path=$1
    if [ -d "$_mount_path" ]; then
        rm -R $_mount_path
        if [ "$?" != "0" ]; then handle_error "Failed to remove mount folder"; fi
    fi
}

function mount_input(){
    local _input_path=$1
   
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
            if [ "$?" != "0" ]; then handle_error "Failed to unmount the folder s'${_input_path}2'"; fi
        fi
       
        remove_mount_path $MOUNT_PATH
        mkdir $MOUNT_PATH

        # not mounted -> mount
        local _offset="$(sudo fdisk -l $_input_path | grep -o -i -P $_input_path'2\s+[0-9]+[^0-9]' | sed -r -e 's/'${_input_path//\//\\/}'2 +//g')"
        if [ "$_offset" == "" ]; then handle_error "Failed to find out the offset"; fi          
        sudo mount -o loop,offset=$((512*$_offset)) $_input_path $MOUNT_PATH
        if [ "$?" != "0" ]; then handle_error "Failed to mount image file"; fi 
    
    else

        mkdir $MOUNT_PATH
        # image file :
        local _offset="$(sudo fdisk -l $_input_path | grep -o -i -P $_input_path'2\s+[0-9]+[^0-9]' | sed -r -e 's/'${_input_path//\//\\/}'2 +//g')"
        if [ "$_offset" == "" ]; then handle_error "Failed to find out the offset"; fi
        sudo mount -o loop,offset=$((512*$_offset)) $_input_path $MOUNT_PATH
        if [ "$?" != "0" ]; then handle_error "Failed to mount image file"; fi         
    fi
}

function umount_input(){
    local _input_path=$1
    echo "- Unmount path : '$_input_path'"

    sudo umount -l $_input_path
    if [ "$?" != "0" ]; then handle_error "Failed to unmount the folder s'$_input_path'"; fi                 
    remove_mount_path $_input_path    
}

function enable_emulation(){
    local _input_path=$1
    local _value=$2
            
    mount_input $_input_path
                         
    if [ "$_value" == "1" ]; then
    
        echo "- Enable emulation on '$_input_path' with value=$_value"
    
        if [ ! -f "$MOUNT_PATH/etc/ld.so.preload" ]; then
            umount_input $MOUNT_PATH 
            handle_error "File $MOUNT_PATH/etc/ld.so.preload does not exists"
        else
            if [ -f "$MOUNT_PATH/etc/ld.so.preload.original" ]; then
                echo "- System is already in emulation state"
            else
                echo ""
                echo " - Replace $MOUNT_PATH/etc/ld.so.preload > $MOUNT_PATH/etc/ld.so.preload.original"
                echo ""
                sudo cp $MOUNT_PATH/etc/ld.so.preload $MOUNT_PATH/etc/ld.so.preload.original
                # Check if the line to comment exists : /usr/lib/arm-*/libarmmem.so                  
                sudo sed -i '/\/usr\/lib\/arm-.*\/libarmmem.so/ s/^/#/' $MOUNT_PATH/etc/ld.so.preload
            fi
        fi

        if [ ! -f "$MOUNT_PATH/etc/fstab" ]; then
            umount_input $MOUNT_PATH
            handle_error "File $MOUNT_PATH/etc/fstab does not exists"    
        else   
            if [ -f "$MOUNT_PATH/etc/fstab.original" ]; then
                echo "- System is already in emulation state"
            else
                echo ""
                echo " - Replace $MOUNT_PATH/etc/fstab > $MOUNT_PATH/etc/fstab.original"
                echo ""
                sudo cp $MOUNT_PATH/etc/fstab $MOUNT_PATH/etc/fstab.original
                sudo sed -i '/dev\/mmcblk/ s?^?#?' $MOUNT_PATH/etc/fstab
            fi
        fi    
    
    elif [ "$_value" == "0" ]; then    
    
        echo "- Disable emulation on '$_input_path' with value=$_value"

        if [ ! -f "$MOUNT_PATH/etc/ld.so.preload.original" ]; then
            echo "- System is already in its original state"
        else
            echo ""
            echo " - Replace $MOUNT_PATH/etc/ld.so.preload.original > $MOUNT_PATH/etc/ld.so.preload"
            echo ""
            sudo rm $MOUNT_PATH/etc/ld.so.preload
            sudo mv $MOUNT_PATH/etc/ld.so.preload.original $MOUNT_PATH/etc/ld.so.preload
        fi
           
        if [ ! -f "$MOUNT_PATH/etc/fstab.original" ]; then
            echo "-- System is already in its original state"
        else        
            echo ""
            echo " - Replace $MOUNT_PATH/etc/fstab.original > $MOUNT_PATH/etc/fstab"
            echo ""
            sudo rm $MOUNT_PATH/etc/fstab
            sudo mv $MOUNT_PATH/etc/fstab.original $MOUNT_PATH/etc/fstab
        fi
    fi
        
    umount_input $MOUNT_PATH    
}


##########################################################################
# Script
##########################################################################


if [ $# -ne 2 ]; then
    echo "Number of arguments is not 2"
    help
    exit 1
fi 

MOUNT_PATH="_mnt"
INPUT_PATH=$1
VALUE=$2

enable_emulation $INPUT_PATH $VALUE   



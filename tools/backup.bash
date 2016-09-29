#!/bin/bash

echo "---------------------------------------------------------------"
echo "---- The script to backup the SD card "
echo "---- Usage : $ bash backup.bash /dev/sd* path/to/output.img"
echo "---------------------------------------------------------------"

echo ""
echo "Executed cmd : sudo ddrescue $1 $2 -S --size=14080M"
echo ""

input_device=$1
output_img=$2

sudo umount ${input_device}1
sudo umount ${input_device}2
sudo ddrescue $input_device $output_img -S --size=15080M
sudo chmod 777 $output_img

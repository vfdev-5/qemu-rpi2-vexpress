# Start Raspberry Pi 2 image in QEMU

In this project you can find some scripts to launch QEMU on image from SD card of Raspberry Pi 2 (rpi2) as ARMv7 (vexpress-a9 or vexpress-a15). 

*For example, you can dump [Ubuntu Mate 16.04 armhf](https://ubuntu-mate.org/raspberry-pi/ubuntu-mate-16.04-desktop-armhf-raspberry-pi.img.xz) to an SD card and start it in QEMU emulator*

This project is similar to [qemu-rpi-kernel](https://github.com/dhruvvyas90/qemu-rpi-kernel/) where `versatilepb` machine used in QEMU (equivalent to ARMv6). 

## QEMU installation:

You need to use `qemu-system-arm`, to install qemu execute the following :

```
sudo apt-get install qemu
```

## Usage :

**Important: Certain files on the SD card image are modified in order to start emulation in QEMU.**

- Insert micro SD and findout its device file. For example, device root file is `/dev/sdb`
- in terminal start command :

```
bash start.bash /dev/sdb [--no-verbose]
```

### Image modifications for QEMU:

QEMU emulation requires modification in /etc/fstab and /etc/ld.so.preload files
For more details, see, for example, [here](http://stackoverflow.com/questions/38837606/emulate-raspberry-pi-raspbian-with-qemu/39676138) or [here](http://blog.3mdeb.com/2015/12/30/emulate-rapberry-pi-2-in-qemu/) or even [here](https://github.com/dhruvvyas90/qemu-rpi-kernel/blob/master/tools/qemu_choose_vm.sh)

Thus, `start.bash` script mounts the device to access its system files, copies original `/etc/fstab` and `/etc/ld.so.preload` and comments the lines:

```
/dev/mmcblk0p2  /               ext4   defaults,noatime  0       1
/dev/mmcblk0p1  /boot/          vfat    defaults          0       2
```

and 

```
/usr/lib/arm-linux-gnueabihf/libarmmem.so
```

## Details : 

The command to launch QEMU emulator on `/dev/sdb` is 

```
sudo qemu-system-arm -m 2048M -M vexpress-a15 -cpu cortex-a15 -kernel kernel-qemu-4.4.1-vexpress -no-reboot -dtb vexpress-v2p-ca15_a7.dtb -sd /dev/sdb -append "root=/dev/mmcblk0p2 rw rootfstype=ext4"
```

#### Linux kernel 4.4.1 and DTB

Linux kernel used with QEMU is a build of [Linux 4.4.1](https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.4.1.tar.xz) configured on `vexpress` :

```

$ cd linux-4.4.1
$ make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- vexpress_defconfig
$ cat >> .config << EOF
> CONFIG_FHANDLE=y
> CONFIG_LBDAF=y
> EOF
$ make -j4 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- all
...
$ cp arch/arm/boot/zImage ../kernel-qemu-4.4.1-vexpress
$ cp arch/arm/boot/dts/vexpress-*.dtb ../

```









 





#!/bin/bash

echo "Installing required tools"
apt-get install -y aptitude
aptitude install squashfs-tools genisoimage

echo "Setting up working directory"
mkdir ~/livecdtmp
mv ubuntu-11.04-desktop-amd64.iso ~/livecdtmp/
cd ~/livecdtmp

echo "Extracting contents of image"
mkdir mnt
mount -o loop ubuntu-9.04-desktop-i386.iso mnt
mkdir extract-cd
rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd

unsquashfs mnt/casper/filesystem.squashfs
mv squashfs-root edit

echo "Preparing for chroot"
cp /run/resolvconf/resolv.conf edit/etc/
cp /etc/hosts edit/etc/

mount --bind /dev/ edit/dev
chroot edit

echo "Entered chroot and mounting required directories"
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devpts none /dev/pts
export HOME=/root
export LC_ALL=C

echo "Customizing build to fit requirements"
dbus-uuidgen > /var/lib/dbus/machine-id
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl

apt-get remove --purge -y libreoffice*
apt-get clean
apt-get autoremove
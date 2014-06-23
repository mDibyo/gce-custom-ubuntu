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

ln -s /lib/init/upstart-job /etc/init.d/whoopsie
apt-get update
apt-get upgrade -u -y

apt-get remove --purge -y libreoffice*

echo "Making changes required by Google Compute Engine"

# Time related changes
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
sudo tee -a /etc/cron.hourly/ntpdate <<EOF
#!/bin/bash

ntpdate time1.google.com
EOF

# Necessary google packages
apt-get install -y kpartx ethtool curl
wget https://github.com/GoogleCloudPlatform/compute-image-packages/releases/download/1.1.2/python-gcimagebundle_1.1.2-1_all.deb https://github.com/GoogleCloudPlatform/compute-image-packages/releases/download/1.1.2/google-compute-daemon_1.1.2-1_all.deb https://github.com/GoogleCloudPlatform/compute-image-packages/releases/download/1.1.2/google-startup-scripts_1.1.2-1_all.deb
dpkg -i google-compute-daemon_1.1.2-1_all.deb google-startup-scripts_1.1.2-1_all.deb python-gcimagebundle_1.1.2-1_all.deb

# Necessary configurations
rm /etc/hostname
echo "169.254.169.254 metadata.google.internal metadata" >> /etc/hosts
ln -s /usr/share/google/set-hostname /etc/dhcp/dhclient-exit-hooks.d/



apt-get clean
apt-get autoremove
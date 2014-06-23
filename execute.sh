#!/bin/bash

echo "Installing required tools"
apt-get install -y aptitude
aptitude install squashfs-tools genisoimage

echo "Setting up working directory"
mkdir ~/livecdtmp
mv ubuntu-14.04-desktop-amd64.iso ~/livecdtmp/
cd ~/livecdtmp

echo "Extracting contents of image"
mkdir mnt
mount -o loop ubuntu-14.04-desktop-amd64.iso mnt
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
tee -a /etc/cron.hourly/ntpdate <<EOF
#!/bin/bash

ntpdate time1.google.com
EOF

# Necessary google packages
apt-get install -y kpartx ethtool curl
apt-get -f install 
dpkg --configure curl rsync uuid-runtime
wget https://github.com/GoogleCloudPlatform/compute-image-packages/releases/download/1.1.2/python-gcimagebundle_1.1.2-1_all.deb \
https://github.com/GoogleCloudPlatform/compute-image-packages/releases/download/1.1.2/google-compute-daemon_1.1.2-1_all.deb \
https://github.com/GoogleCloudPlatform/compute-image-packages/releases/download/1.1.2/google-startup-scripts_1.1.2-1_all.deb
dpkg -i google-compute-daemon_1.1.2-1_all.deb \
google-startup-scripts_1.1.2-1_all.deb \
python-gcimagebundle_1.1.2-1_all.deb

# Necessary configurations
rm /etc/hostname
echo "169.254.169.254 metadata.google.internal metadata" >> /etc/hosts
ln -s /usr/share/google/set-hostname /etc/dhcp/dhclient-exit-hooks.d/
tee -a /etc/init/ttyS0.conf <<EOF
# ttS0 - getty
start on stopped rc or RUNLEVEL=[2345]
stop on runlevel [!2345]
respawn
exec /sbin/getty -L 115200 ttyS0 vt102
EOF
tee -a /etc/default/grub <<EOF

GRUB_CMDLINE_LINUX="console=ttyS0,115200n8 ignore_loglevel"
GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"
GRUB_TERMINAL=console
EOF
sed -i 's/^GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="console=ttyS0,115200n8 ignore_loglevel"\nGRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"/' /etc/default/grub
sed -i 's/^#GRUB_TERMINAL=console/GRUB_TERMINAL=console/' /etc/default/grub
update-grub2

# Network changes
echo "GOOGLE" > /etc/ssh/sshd_not_to_be_run
tee -a /etc/sysctl.d/12-gce-recommended.conf <<EOF
# provides protection from ToCToU races
fs.protected_hardlinks=1
# provides protection from ToCToU races
fs.protected_symlinks=1
# makes locating kernel addresses more difficult
kernel.kptr_restrict=1
# set ptrace protections
kernel.yama.ptrace_scope=1
# set perf only available to root
kernel.perf_event_paranoid=2
# disable ipv6
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
EOF

echo "Cleaning up"
apt-get clean
apt-get autoremove

rm /var/lib/dbus/machine-id
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl

umount /proc || umount -lf /proc
umount /sys
umount /dev/pts
exit
umount edit/dev

echo "Producing image"
chmod +w extract-cd/casper/filesystem.manifest
chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' > extract-cd/casper/filesystem.manifest
cp extract-cd/casper/filesystem.manifest extract-cd/casper/filesystem.manifest-desktop
sed -i '/ubiquity/d' extract-cd/casper/filesystem.manifest-desktop
sed -i '/casper/d' extract-cd/casper/filesystem.manifest-desktop

rm extract-cd/casper/filesystem.squashfs
mksquashfs edit extract-cd/casper/filesystem.squashfs # -nolzma

printf $(sudo du -sx --block-size=1 edit | cut -f1) > extract-cd/casper/filesystem.size
sed -i 's/^#define DISKNAME  Ubuntu 14.04 LTS "Trusty Tahr" - Release amd64/#define DISKNAME  Ubuntu 14.04 LTS "Trusty Tahr" - Release amd64 EDIT/' extract-cd/README.diskdefines

cd extract-cd
rm md5sum.txt
find -type f -print0 | xargs -0 md5sum | grep -v isolinux/boot.cat | tee md5sum.txt

mkisofs -D -r -V "$IMAGE_NAME" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ../ubuntu-14.04.1-desktop-amd64-custom.iso .
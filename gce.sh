sudo su

# Necessary google packages
apt-get install -y curl
wget https://github.com/GoogleCloudPlatform/compute-image-packages/releases/download/1.1.2/python-gcimagebundle_1.1.2-1_all.deb \
https://github.com/GoogleCloudPlatform/compute-image-packages/releases/download/1.1.2/google-compute-daemon_1.1.2-1_all.deb \
https://github.com/GoogleCloudPlatform/compute-image-packages/releases/download/1.1.2/google-startup-scripts_1.1.2-1_all.deb
dpkg -i google-compute-daemon_1.1.2-1_all.deb \
google-startup-scripts_1.1.2-1_all.deb \
python-gcimagebundle_1.1.2-1_all.deb

# Necessary configurations
sudo rm /etc/hostname
sudo echo "169.254.169.254 metadata.google.internal metadata" >> /etc/hosts
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
rm /etc/ssh/ssh_host_*
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

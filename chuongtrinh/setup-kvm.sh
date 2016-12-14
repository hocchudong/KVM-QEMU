#!/bin/bash 
##############################################################################
# Script cai dat KVM va Linux bridge
# @hocchudong
##############################################################################

echo "Update he thong"
apt-get update

echo "====Cai dat kvm-qemu, linuxbridge ===="
sleep 2
apt-get -y install qemu-kvm libvirt-bin virtinst bridge-utils
modprobe vhost_net 
lsmod | grep vhost 
echo vhost_net >> /etc/modules 

echo "Cai dat goi de su dung duoc X11 tren host"
# Goi cai dat nay se giup cau hinh Xming de dieu khien KVM tu windows
sudo apt-get -y install xorg openbox

echo "Cau hinh network"
iface=/etc/network/interfaces
test -f $iface || cp $iface $iface.copy
rm -rf $iface
touch	$iface
cat << EOF >> $iface
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5)
auto lo
iface lo inet loopback

##
auto br0
iface br0 inet dhcp
bridge_ports eth0
bridge_stp off
bridge_fd 0
bridge_maxwait 0

# Card mang eth1
auto eth1
iface eth1 inet dhcp
# Design by Nguyen Hoai Nam
EOF

echo "Qua trinh cai dat qemu-kvm da xong"
echo "Cai dat virt-manager"
sleep 2
apt-get  -y install virt-manager qemu-system hal

echo "Khoi dong lai he thong"
sleep 2
reboot

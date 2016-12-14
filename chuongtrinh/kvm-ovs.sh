################################################################################
# Noi dung: Script cai dat KVM, OpenvSwitch
# Nguoi thuc hien: congto@hocchudong.com
# Yeu cau: 
## OS: Ubuntu 14.04 64 bit
## May cai KVM va OpenvSwitch can 02 NICs. 
## NIC1 su dung hostonly, NIC2 su dung NAT va duoc add vao bridge cua OpenvSwitch
# Cach thuc thi: sudo bash kvm-ovs.sh
################################################################################
#!/bin/bash 

if [ `id -u` -ne 0 ]; then
   echo -e "\e[1;31m You need root privileges to run this script \e[0m"
   exit 1
fi

# print yellow text
function echocolor {
	echo -e "\e[1;33m ########## $1 ########## \e[0m"
}

echocolor "Update cac goi cai dat tren OS"
sleep 3
apt-get -y update

echocolor "Cau hinh ssh cho phep dang nhap root tu xa"
sleep 3
sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
serivce ssh restart

echocolor "Cai dat KVM va cac goi ho tro"
sleep 3
apt-get -y install qemu-kvm libvirt-bin bridge-utils virtinst
sudo adduser `id -un` libvirtd
sudo adduser `id -un` kvm

echocolor "Go bo bridge cua Linux bridge"
sleep 3
virsh net-destroy default
virsh net-autostart --disable default

echocolor "Cai dat virt-manage va cac goi bo tro"
sleep 3
apt-get -y install virt-manager xorg openbox


echocolor "Cai dat OpenvSwitch"
sleep 3
apt-get -y install openvswitch-controller openvswitch-switch openvswitch-datapath-source

echocolor "Cau hinh them cho OVS"
sleep 3
sudo echocolor "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf

echocolor "Kiem tra trang  thai cua OVS"
sleep 3
service openvswitch-switch status

echocolor "Cau hinh NICs cho may chu"
sleep 3
cat << EOF > /etc/network/interfaces

# ETH0
auto eth0
iface eth0 inet dhcp

# ETH1
auto eth1
iface eth1 inet manual
up ifconfig \$IFACE 0.0.0.0 up
up ip link set \$IFACE promisc on
down ip link set \$IFACE promisc off
down ifconfig \$IFACE down

# Dat IP dong cho bridge "br0". Interface nay duoc gan vao br0 cua OpenvSwitch
auto br0
iface br0 inet dhcp

EOF

echocolor "Tao bridge va gan port (interface) cho OVS"
sleep 3
ovs-vsctl add-br br0
ovs-vsctl add-port br0 eth1

echocolor "Khai bao netwok libvirtd, su dung br0 cua OVS"
sleep 3
cat << EOF > ovsnet.xml
<network>
  <name>br0</name>
  <forward mode='bridge'/>
  <bridge name='br0'/>
  <virtualport type='openvswitch'/>
</network>
EOF

virsh net-define ovsnet.xml
virsh net-start br0
virsh net-autostart br0

echocolor "Khoi dong lai network cua may chu"
sleep 3
ifdown --force -a && ifup --force -a

echocolor "Khoi dong lai may chu"
sleep 3
init 6
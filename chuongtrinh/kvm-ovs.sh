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

echo "Update cac goi cai dat tren OS"
sleep 3
apt-get -y update

echo "Cau hinh ssh cho phep dang nhap root tu xa"
sleep 3
sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
serivce ssh restart

echo "Cai dat KVM va cac goi ho tro"
sleep 3
apt-get -y install qemu-kvm libvirt-bin bridge-utils virtinst
sudo adduser `id -un` libvirtd
sudo adduser `id -un` kvm

echo "Go bo bridge cua Linux bridge"
sleep 3
virsh net-destroy default
virsh net-autostart --disable default

echo "Cai dat virt-manage va cac goi bo tro"
sleep 3
apt-get -y install virt-manager xorg openbox


echo "Cai dat OpenvSwitch"
sleep 3
apt-get -y install openvswitch-controller openvswitch-switch openvswitch-datapath-source

echo "Cau hinh them cho OVS"
sleep 3
sudo echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf

echo "Kiem tra trang  thai cua OVS"
sleep 3
service openvswitch-switch status

echo "Cau hinh NICs cho may chu"
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

echo "Tao bridge va gan port (interface) cho OVS"
sleep 3
ovs-vsctl add-br br0
ovs-vsctl add-port br0 eth1

echo "Khai bao netwok libvirtd, su dung br0 cua OVS"
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

echo "Khoi dong lai network cua may chu"
sleep 3
ifdown --force -a && ifup --force -a

echo "Khoi dong lai may chu"
sleep 3
init 6
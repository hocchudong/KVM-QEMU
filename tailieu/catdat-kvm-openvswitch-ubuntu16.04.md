# Update and install the needed packages
PACKAGES="qemu-kvm libvirt-bin bridge-utils virtinst"
sudo apt-get update
sudo apt-get dist-upgrade -qy

sudo apt-get install -qy ${PACKAGES}

# add our current user to the right groups
sudo adduser `id -un` libvirtd
sudo adduser `id -un` kvm


sudo virsh net-destroy default 
sudo virsh net-autostart --disable default

sudo apt-get install -qy openvswitch-switch openvswitch-common 
sudo service openvswitch-switch start


sudo echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf

sudo ovs-vsctl add-br br0
sudo ovs-vsctl add-port br0 ens32

- Thiet lap card mang 

cat << EOF > /etc/network/interfaces

# ens32
auto ens32
iface ens32 inet manual


# The OVS bridge interface
auto br0
iface br0 inet dhcp
# address 10.0.0.4
# network 10.0.0.0
# netmask 255.255.0.0
# broadcast 10.0.255.255
# gateway 10.0.0.2
dns-nameservers 8.8.8.8 8.8.4.4
dns-search test.local
bridge_ports ens32
bridge_fd 9
bridge_hello 2
bridge_maxage 12
bridge_stp off

auto ens33
iface ens33 inet dhcp

EOF

sudo ifdown --force -a && sudo ifup --force -a

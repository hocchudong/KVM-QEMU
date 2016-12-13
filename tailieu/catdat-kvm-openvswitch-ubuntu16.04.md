# Hướng dẫn cài đặt KVM, OpenvSwitch trên Ubuntu 16.04

- Tham khảo: http://blog.codybunch.com/2016/10/14/KVM-and-OVS-on-Ubuntu-1604/

## Yêu cầu cấu hình:
- Môi trường giả lập: VMware Workstation 
- Hệ điều hành: Ubuntu 16.04 Server 64 bit (máy cài KVM và OpenvSwitch)
- NIC1: Sử dụng hostonly của vmware workstation. Có tên là `ens32`
- NIC2: Sử dụng NAT hoặc bridge(sẽ thực hiện bridge và NIC này). Có tên là `ens33`

## Các bước cài đặt
### Cài đặt KVM và các gói phụ trợ

- Cài đặt KVM
	```sh 
	echo  "Update and install the needed packages"
	PACKAGES="qemu-kvm libvirt-bin bridge-utils virtinst"
	sudo apt-get update
	sudo apt-get dist-upgrade -qy

	sudo apt-get install -qy ${PACKAGES}
	```

- Gán quyền cho user `libvirtd` và `kvm`
	```sh
	sudo adduser `id -un` libvirtd
	sudo adduser `id -un` kvm
	```

- Xóa các bridge do Linux Bridge khi cài cùng KVM sinh ra
	```sh
	sudo virsh net-destroy default 
	sudo virsh net-autostart --disable default
	```

### Cài đặt và cấu hình OpenvSwitch

- Cài đặt OpenvSwtich
	```sh
	sudo apt-get install -qy openvswitch-switch openvswitch-common 
	sudo service openvswitch-switch start
	```
	
- Cấu hình hỗ trợ thêm OpenvSwitch
	```sh
	sudo echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
	sudo sysctl -p /etc/sysctl.conf
	```

- Tạo bridge trên OpenvSwitch và gán NIC của máy chủ vào bridge này. Ví dụ này là `ens32`
	```sh
	sudo ovs-vsctl add-br br0
	sudo ovs-vsctl add-port br0 ens32
	```

### Cấu hình network cho máy chủ Ubuntu

- Cấu hình network 

	```sh
	cat << EOF > /etc/network/interfaces

	# ens32
	auto ens32
	iface ens32 inet manual


	# Dat IP dong cho bridge `br0`
	auto br0
	iface br0 inet dhcp
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
	```

- Restart lại network của máy chủ

	```sh
	sudo ifdown --force -a && sudo ifup --force -a
	```
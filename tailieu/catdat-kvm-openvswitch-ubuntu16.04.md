# Hướng dẫn cài đặt KVM, OpenvSwitch trên Ubuntu 16.04

- Tham khảo: http://blog.codybunch.com/2016/10/14/KVM-and-OVS-on-Ubuntu-1604/

## Yêu cầu cấu hình:
- Môi trường giả lập: VMware Workstation 
- Hệ điều hành: Ubuntu 16.04 Server 64 bit (máy cài KVM và OpenvSwitch)
- NIC1: Sử dụng hostonly của vmware workstation. Có tên là `ens32`. Dùng để quản trị.vi 
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

- Do khi cài KVM thì mặc định `Linux Bridge` (Linux Bridge là một trong các sự lựa chọn để ảo hóa network trong Linux - tương đương với OpenvSwtich) sẽ được cài cùng và sinh ra bridge `virbr0`. Có thể kiểm tra bằng lệnh dưới, ta sẽ thấy có tên bridge.
	```sh
	brctl show
	```

- Do vây, ta sẽ xóa các bridge do Linux Bridge khi cài cùng KVM sinh ra để sử dụng OpenvSwitch
	```sh
	sudo virsh net-destroy default 
	sudo virsh net-autostart --disable default
	```

- Kiểm tra lại bằng lệnh `brctl show` ta sẽ không thấy bridge `virbr0`. Lúc này OK
	```sh
	root@u16-com2:~# brctl show
	bridge name     bridge id               STP enabled     interfaces
	```


### Cài đặt và cấu hình OpenvSwitch

- Cài đặt OpenvSwtich
	```sh
	sudo apt-get install -qy openvswitch-switch openvswitch-common 
	sudo service openvswitch-switch start
	```

- Kiểm tra phiên bản của OpenvSwtich bằng lệnh
	```sh
	ovs-vsctl -V
	```

 - Kết quả là: (OpenvSwitch phiên bản 2.5.0)
 
	 	```sh
		ovs-vsctl (Open vSwitch) 2.5.0
		Compiled Mar 10 2016 14:16:49
		DB Schema 7.12.1
		root@u16-com2:~#
		```

- Cấu hình hỗ trợ thêm OpenvSwitch
	```sh
	sudo echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
	sudo sysctl -p /etc/sysctl.conf
	```

- Tạo bridge trên OpenvSwitch và gán NIC của máy chủ vào bridge này. Ví dụ này là `ens32`
	```sh
	sudo ovs-vsctl add-br br0
	sudo ovs-vsctl add-port br0 ens33
	```

### Cấu hình network cho máy chủ Ubuntu

- Cấu hình network 

	```sh
	cat << EOF > /etc/network/interfaces

	# ens32
	auto ens32
	iface ens32 inet dhcp


	# Dat IP dong cho bridge `br0`. Interface nay duoc gan vao br0 cua OpenvSwitch

	auto br0
	iface br0 inet dhcp
	bridge_ports ens33
	bridge_fd 9
	bridge_hello 2
	bridge_maxage 12
	bridge_stp off

	# ens33
	auto ens33
	iface ens33 inet manual


	EOF
	```

- Restart lại network của máy chủ

	```sh
	sudo ifdown --force -a && sudo ifup --force -a
	```
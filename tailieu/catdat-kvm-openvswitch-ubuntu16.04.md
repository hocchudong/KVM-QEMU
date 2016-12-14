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

- Kiểm tra xem bridge và interface đã được gán trong OpenvSwitch hay chưa
	```sh
	ovs-vsctl show
	```

 - Kết quả là

		```sh
		9be04e06-1c0b-43f6-b713-411d91d0cb28
		    Bridge "br0"
		        Port "br0"
		            Interface "br0"
		                type: internal
		        Port "ens33"
		            Interface "ens33"
		    ovs_version: "2.5.0"
		root@u16-com2:~#
		```

### Cấu hình network cho máy chủ Ubuntu

- Cấu hình network 

	```sh
	cat << EOF > /etc/network/interfaces

	# ens32
	auto ens32
	iface ens32 inet dhcp

	# ens33
	auto ens33
	iface ens33 inet manual
	up ifconfig \$IFACE 0.0.0.0 up
	up ip link set \$IFACE promisc on
	down ip link set \$IFACE promisc off
	down ifconfig \$IFACE down

	# Dat IP dong cho bridge "br0". Interface nay duoc gan vao br0 cua OpenvSwitch
	auto br0
	iface br0 inet dhcp
	# address 172.16.69.99
	# netmask 255.255.255.0
	# gateway 172.16.69.1
	# dns-nameservers 8.8.8.8

	EOF
	```

- Restart lại network của máy chủ
	```sh
	sudo ifdown --force -a && sudo ifup --force -a
	```

- Chuyển sang bước tạo máy ảo

## Tạo máy ảo trong KVM và sử dụng Network là OpenvSwitch

- Tham khảo cách sử dụng Virt Virtual Machine (VMM)

### Cài đặt virt-manage và X11 để sử dụng công cụ virt virtual machine

- Cài đặt virt-manage
	```sh
	apt-get install -y virt-manager xorg openbox
	```

- Cài đặt gói dưới để fix lỗi khi gõ lệnh virt-manage
	```sh
	Couldn't open libGL.so.1: libGL.so.1: cannot open shared object file: No such file or directory
	```

	```sh
	apt-get install libglu1-mesa -y
	```
	
- Tùy chọn: có thể sửa dòng 28 trong file ` /etc/ssh/sshd_config` để cho phép ssh bằng tài khoản `root` từ xa, dòng đó sửa thành dòng dưới. Tùy chọn này cho phép dùng `virt-manage` với tài khoản root.
	```sh
	PermitRootLogin yes
	```

### Cấu hình network cho KVM sử dụng openvswitch
- Nếu không cấu hình bước này, khi dùng lệnh `virt-install` tạo máy ảo, mặc định sẽ sử dụng Linux Bridge
- Kiểm tra xem có các network nào trong KVM 
	```sh
	virsh net-list --all
	```

- Mặc định sẽ có 1 network tên là `default`, chính network này sẽ sử dụng Linux Bridge, do vậy cần tiến hành tạo network mới để libvirt sử dụng.
- Tạo file cho libvirt network
	```sh
	cat << EOF > ovsnet.xml
	<network>
	  <name>br0</name>
	  <forward mode='bridge'/>
	  <bridge name='br0'/>
	  <virtualport type='openvswitch'/>
	</network>
	EOF
	```


- Thực hiện lệnh để tạo network 
	```sh
	virsh net-define ovsnet.xml
	virsh net-start br0
	virsh net-autostart br0
	```

- Kiểm tra lại network đã khai báo cho libvirt bằng lệnh `virsh net-list --all`, chúng ta sẽ nhìn thấy network có tên là `br0`, đây chính là network có type là `openvswitch` đã khai báo ở trên.
	```sh
	 Name                 State      Autostart     Persistent
	----------------------------------------------------------
	 br0                  active     yes           yes
	 default              inactive   no            yes

	root@u16-com2:~#
	```

### Tạo máy ảo gắn vào bridge của OpenvSwitch

### Cách 1: Tạo bằng lệnh từ file img có sẵn

- Tải file image (giống như file ghost) về để khởi động, ví dụ này sẽ images linux được thu gọn. File được đặt trong thư mục chứa images của KVM (thư mục `/var/lib/libvirt/images`)
	```sh
	cd /var/lib/libvirt/images
	wget wget https://ncu.dl.sourceforge.net/project/gns-3/Qemu%20Appliances/linux-microcore-3.8.2.img
	```

- Khởi động máy ảo với iamges vừa down về bằng lệnh `virt-manage`
- Lựa chọn 1: sử dụng tùy chọn `--network bridge=br0,virtualport_type='openvswitch'`
	```sh
	cd /root/

	sudo virt-install \
	     -n VM01 \
	     -r 128 \
	      --vcpus 1 \
	     --os-variant=generic \
	     --disk path=/var/lib/libvirt/images/test.img,format=qcow2,bus=virtio,cache=none \
	     --network bridge=br0,virtualport_type='openvswitch' \
	     --hvm --virt-type kvm \
	     --vnc --noautoconsole \
	     --import
	```

- Lựa chọn 2: Sử dụng tùy chọn ` --network network=br0` (đối với Ubuntu 14 nên lựa chọn tùy chọn này)
	```sh
	cd /root/

	sudo virt-install \
	     -n VM01 \
	     -r 128 \
	      --vcpus 1 \
	     --os-variant=generic \
	     --disk path=/var/lib/libvirt/images/test.img,format=qcow2,bus=virtio,cache=none \
	     --network network=br0 \
	     --hvm --virt-type kvm \
	     --vnc --noautoconsole \
	     --import
	```


- Dùng VMM để quan sát máy ảo vừa tạo, nếu dùng Putty cần cấu hình Forward X11 phía client (phía máy SSH vào máy chủ) theo [tài liệu này](https://github.com/hocchudong/KVM-QEMU/blob/master/tailieu/huongdansudung-Virsh-Virtual-Machine.md)
- Cài đặt và khởi động Xming
- Thực hiện lệnh 
	```sh
	sudo virt-manage
	```	

### Cách 2: Tạo máy ảo bằng công cụ đồ họa VMM trên windows

- Tham khảo cách sử dụng công cụ đồ họa `VVM` ở đây : [Link](https://github.com/hocchudong/KVM-QEMU/blob/master/tailieu/huongdansudung-Virsh-Virtual-Machine.md)
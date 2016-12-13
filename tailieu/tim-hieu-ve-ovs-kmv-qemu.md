##1. Giới thiệu
<ul></ul>
<ul></ul>
<ul></ul>

##2. Cài đặt
###a. Cài đặt KVM, OVS

- Trong phần này, tôi sẽ đi sâu về Ubuntu Linux, KVM và Open vSwitch (OVS)
- Trong bài test của tôi sử dụng Ubuntu server 14.04 LTS được cài trên máy ảo VMware. Lưu ý trong CPU chọn 02 tick hỗ trợ ảo hóa để hỗ trợ KVM. 
- Đầu tiên cần tiến hành update, upgrade cho máy ảo
	```sh
	apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y
	```

- Kế tiếp, chúng ta sẽ cài đặt KVM và 02 gói hỗ trợ
	```sh
	apt-get install kvm libvirt-bin virtinst -y
	```

- Chuẩn bị cài OVS, chúng ta sẽ gỡ bridge libvirt mặc định (name: virbr0).	
	```sh
	virsh net-destroy default
	virsh net-autostart --disable default
	```

- Vì chúng ta không sử dụng linux bridge mặc định, chúng ta có thể gỡ các gói ebtables bằng lệnh sau. (Không chắc chắn 100% là bước này cần thiết, nhưng hầu hết các bài 
hướng dẫn sẽ có bước này).
	```sh
	aptitude purge ebtables -y
	```

- Chúng ta sẽ cài OVS bằng lệnh sau.
	```sh
	apt-get install openvswitch-controller openvswitch-switch openvswitch-datapath-source -y
	```

Các gói OVS được cài đặt xong, chúng ta sẽ check KVM bằng lệnh sau:
	```sh
	virsh -c qemu:///system list
	```

- Lệnh trên trả về danh sách các VM (máy ảo) đang chạy, lúc này sẽ trống.
- Kiểm tra lại OVS bằng lệnh sau:
	```sh
	service openvswitch-switch status
	```

- Trả về trạng thái của OVS process
- Nếu mọi thứ làm việc đúng, bạn có thể chạy lệnh:
	```sh
	ovs-vsctl show
	```

Việc cuối cùng cần làm là tạo OVS bridge cho phép KVM kết nối tới để đi ra ngoài. Để làm được điều này, chúng ta sẽ xử lý 02 bước sau

- B1: Đầu tiên, sẽ xử dụng lệnh `ovs-vsctl` để tạo bridge và add với 1 physical interface:
	```sh
	ovs-vsctl add-br br0
	ovs-vsctl add-port br0 eth1
	```

- Kiểm tra các bridge đã tạo và interface đã được gán hay chưa
	```sh
	ovs-vsctl show
	fd22e02b-3a43-4200-8f03-d619a2e51b78
		Bridge "br0"
			Port "br0"
				Interface "br0"
					type: internal
			Port "eth1"
				Interface "eth1"
		ovs_version: "2.0.2"
	```

- Command thực hiện restart network: 
	```sh
	ovs-vsctl add-port br0 eth1 && ifdown -a && ifup -a && ifconfig eth1 0 && route add default gw 172.16.69.1
	```

- B2: Sửa file `/etc/network/interfaces` để tạo bridge tự động khi khởi động máy.
	```sh
	root@ubuntu:~# cat /etc/network/interfaces |egrep -v "^#|^$"
	```

- Kết  quả của lệnh trên là
	```sh
	auto lo
	iface lo inet loopback
	auto eth0
	iface eth0 inet static
	address 10.10.10.71
	netmask 255.255.255.0
	auto eth1
	iface eth1 inet manual
	up ifconfig $IFACE 0.0.0.0 up
	up ip link set $IFACE promisc on
	down ip link set $IFACE promisc off
	down ifconfig $IFACE down
	auto br0
	iface br0 inet static
	address 172.16.69.71
	netmask 255.255.255.0
	gateway 172.16.69.1
	network 172.16.69.0
	broadcast 172.16.69.255
	dns-nameservers 8.8.8.8 8.8.4.4
	```

### b. KVM

- Làm việc với KVM chúng ta sẽ sử dụng libvirt. Libvirt là một framework/API mã nguồn mở giúp quản lý nhiều hypervisor và máy ảo

- Nếu bạn đã làm quen với VMware virtualization, bạn sẽ biết VMware-base VM có 2 thành phần chính:
 - VM definition, lưu trữ trong file .VMX
 - VM's storage, lưu trữ trong một hoặc nhiều file .VMDK

- Từ đó tôi có thể xác định KVM guest cũng có 2 thành phần chính:
 - VM definition, xác định trong định dạng XML
 - VM's storage, lưu trữ trong một volume manage bới LVM hoặc một file lưu trong hệ thống 
- Bạn có thể tìm thấy cấu hình XML của một KVM guest theo 2 cách, cả 2 cách đều sử dụng lệnh `virsh` là một phần của libvirt 
 - Sửa file cầu hình của một guest, sử dụng `virsh edit <Name of guest VM>`, hệ thống sẽ mở file XML trong cửa sổ đang làm việc - Xuất file cấu hình của guest, sử dụng lệnh `virsh dumpxml <Name of guest VM>`, lệnh này sẽ dump file cấu hình XML ra STDOUT, bạn có thể chuyển nó vào file nếu muốn.
- Thành phần thứ 2 của KVM guest là storage; như đã nhắc ở trên, cái này có thể là một file trong hệ thống hoặc có thể là một volume managed với một logical volume manager (LVM) 
 - Sửa file cầu hình của một guest, sử dụng `virsh edit <Name of guest VM>`, hệ thống sẽ mở file XML trong cửa sổ đang làm việc
- Xuất file cấu hình của guest, sử dụng lệnh `virsh dumpxml <Name of guest VM>`, lệnh này sẽ dump file cấu hình XML ra STDOUT, bạn có thể chuyển nó vào file nếu muốn.

#### Tạo KVM guest
- Có 02 cách để tạo một KVM guest:
-Tạo thủ công file XML mô tả guest, sử dụng lệnh `virsh define <Name of XML file>` để import vào khai báo. Bạn có thể tạo file XML mới dựa trên file đã có và chỉ thay đổi một vài tham số. 
- Sử dụng libvirt-compatible tool như `virt-install` để tạo guest definition

- Ở đây tạo nhanh một KVM guest sử dụng `virt-install`

```sh
virt-install --name vmname --ram 1024 --vcpus=1 \
--disk path=/var/lib/libvirt/images/vmname.img,size=20,bus=virtio \
--network bridge=ovsbr0 \
--cdrom /home/tannt/ubuntu-14.04.4-server-amd64.iso \
--graphics none --console pty,target_type=serial --hvm \
--os-variant ubuntutrusty --virt-type=kvm --os-type linux
```
- Chi tiết các tham số của lệnh ``virt-install`` có thể tham khảo thêm tại <a href="https://linux.die.net/man/1/virt-install">Link này.

**Note**

- Trong quá trình test, tôi sử dụng lệnh virt-install như trên nhưng bị lỗi, card mạng trên VM tạo ra không thể gán trực tiếp vào ovs. Tôi đã thực hiện tạo VM bằng KVM như sau:

- Thực hiện tạo 02 scritp để add và xóa port trong switch:
	- Script add port vào switch: *vi /etc/ovs-ifup*
```sh
#!/bin/sh
switch='br0'
/sbin/ifconfig $1 0.0.0.0 up
ovs-vsctl add-port ${switch} $1
```
	- Script xóa port trên switch: *vi /etc/ovs-ifdown*
```sh
#!/bin/sh
switch='br0'
/sbin/ifconfig $1 0.0.0.0 down
ovs-vsctl del-port ${switch} $1
```
	- Phân quyền để script có thể thực thi: 
```sh
chmod +x /etc/ovs-ifup /etc/ovs-ifdown
```	

- Thực hiện tạo VM bằng lệnh KVM với cirror image và gán vào ovs bridge "br-int"
	- Lệnh tạo máy ảo 1: 
```sh
kvm -m 512 -net nic,macaddr=00:00:00:00:cc:10 -net tap,script=/etc/ovs-ifup,downscript=/etc/ovs-ifdown -nographic /home/tannt/cirros-0.3.4-x86_64-disk.img
```
	- Lệnh tạo máy ảo 2:
```sh
kvm -m 512 -net nic,macaddr=00:11:22:CC:CC:10 -net tap,script=/etc/ovs-ifup,downscript=/etc/ovs-ifdown -nographic /home/tannt/cirros-0.3.4-x86_64-disk.img
```
	- Lệnh tạo máy ảo 3:
```sh
kvm -m 512 -net nic,macaddr=22:22:22:00:cc:10 -net tap,script=/etc/ovs-ifup,downscript=/etc/ovs-ifdown -nographic /home/tannt/cirros-0.3.4-x86_64-disk.img
```

## Tham khảo
- http://blog.scottlowe.org/2012/08/17/installing-kvm-and-open-vswitch-on-ubuntu/ 
- http://blog.scottlowe.org/2012/08/21/working-with-kvm-guests/
- https://www.rivy.org/2014/04/install-a-kvm-host-on-ubuntu-14-04-trusty-tahr/

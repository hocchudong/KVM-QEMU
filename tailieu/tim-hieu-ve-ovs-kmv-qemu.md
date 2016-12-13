##1. Giới thiệu
<ul></ul>
<ul></ul>
<ul></ul>

##2. Cài đặt
###a. Cài đặt KVM, OVS

<ul>Trong phần này, tôi sẽ đi sâu về Ubuntu Linux, KVM và Open vSwitch (OVS)</ul>
<ul>Trong bài test của tôi sử dụng Ubuntu server 14.04 LTS được cài trên máy ảo VMware. Lưu ý trong CPU chọn 02 tick hỗ trợ ảo hóa để hỗ trợ KVM,</ul>
<ul>Đầu tiên cần tiến hành update, upgrade cho máy ảo
	<li><i>apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y</i></li>
</ul>
<ul>Kế tiếp, chúng ta sẽ cài đặt KVM và 02 gói hỗ trợ
	<li><i>apt-get install kvm libvirt-bin virtinst -y</i></li>
</ul>
<ul>Chuẩn bị cài OVS, chúng ta sẽ gỡ bridge libvirt mặc định (name: virbr0).
	<li><i>virsh net-destroy default</i></li>
	<li><i>virsh net-autostart --disable default</i></li>
</ul>
<ul>Vì chúng ta không sử dụng linux bridge mặc định, chúng ta có thể gỡ các gói ebtables bằng lệnh sau. (Không chắc chắn 100% là bước này cần thiết, nhưng hầu hết các bài 
hướng dẫn sẽ có bước này).
	<li><i>aptitude purge ebtables -y</i></li>
</ul>
<ul>Chúng ta sẽ cài OVS bằng lệnh sau.
	<li><i>apt-get install openvswitch-controller openvswitch-switch openvswitch-datapath-source -y</i></li>
</ul>
<ul>Các gói OVS được cài đặt xong, chúng ta sẽ check KVM bằng lệnh sau:
	<li><i>virsh -c qemu:///system list</i></li>
	<p>Lệnh trên trả về danh sách các VM (máy ảo) đang chạy, lúc này sẽ trống.</p>
</ul>
<ul>Kiểm tra lại OVS bằng lệnh sau:
	<li><i>service openvswitch-switch status</i></li>
	<p>Trả về trạng thái của OVS process</p>
</ul>
<ul>Nếu mọi thứ làm việc đúng, bạn có thể chạy lệnh:
	<li><i>ovs-vsctl show</i></li>
</ul>
<ul>Việc cuối cùng cần làm là tạo OVS bridge cho phép KVM kết nối tới để đi ra ngoài. Để làm được điều này, chúng ta sẽ xử lý 02 bước sau
	<li>B1: Đầu tiên, sẽ xử dụng lệnh <i>ovs-vsctl</i> để tạo bridge và add với 1 physical interface:
		<ul>
			<li><i>ovs-vsctl add-br br0</i></li>
			<li><i>ovs-vsctl add-port br0 eth1</i></li>
			<li><i>ovs-vsctl show</i>
			<pre>
				fd22e02b-3a43-4200-8f03-d619a2e51b78
				Bridge "br0"
					Port "br0"
						Interface "br0"
							type: internal
					Port "eth1"
						Interface "eth1"
				ovs_version: "2.0.2"
			</pre>
			</li>
		</ul>
	</li>
	<li>Command thực hiện restart network: <i>ovs-vsctl add-port br0 eth1 && ifdown -a && ifup -a && ifconfig eth1 0 && route add default gw 172.16.69.1</i></li>
	<li>B2: Sửa file <i>/etc/network/interfaces</i> để tạo bridge tự động khi khởi động máy.
		<pre>
root@ubuntu:~# cat /etc/network/interfaces |egrep -v "^#|^$"
auto lo
iface lo inet loopback
auto eth0
iface eth0 inet static
address 10.10.10.71
netmask 255.255.255.0
auto eth1
iface eth1 inet manual
auto br0
iface br0 inet static
address 172.16.69.71
netmask 255.255.255.0
gateway 172.16.69.1
network 172.16.69.0
broadcast 172.16.69.255
bridge_port eth1
bridge_fd 9
bridge_hello 2
bridge_maxage 12
bridge_stp off
dns-nameservers 8.8.8.8 8.8.4.4
		</pre>
	</li>
</ul>

###b. KVM
<ul>Làm việc với KVM chúng ta sẽ sử dụng libvirt. Libvirt là một framework/API mã nguồn mở giúp quản lý nhiều hypervisor và máy ảo.</ul>
<ul>Nếu bạn đã làm quen với VMware virtualization, bạn sẽ biết VMware-base VM có 2 thành phần chính:
	<li>VM definition, lưu trữ trong file .VMX</li>
	<li>VM's storage, lưu trữ trong một hoặc nhiều file .VMDK</li>
</ul>
<ul>Từ đó tôi có thể xác định KVM guest cũng có 2 thành phần chính:
	<li>VM definition, xác định trong định dạng XML</li>
	<li>VM's storage, lưu trữ trong một volume manage bới LVM hoặc một file lưu trong hệ thống</li>
</ul>
<ul>Bạn có thể tìm thấy cấu hình XML của một KVM guest theo 2 cách, cả 2 cách đều sử dụng lệnh <i>virsh</i> là một phần của libvirt 
	<li>Sửa file cầu hình của một guest, sử dụng <i>virsh edit <Name of guest VM></i>, hệ thống sẽ mở file XML trong cửa sổ đang làm việc</li>
	<li>Xuất file cấu hình của guest, sử dụng lệnh <i>virsh dumpxml <Name of guest VM></i>, lệnh này sẽ dump file cấu hình XML ra STDOUT, bạn có thể chuyển nó vào file nếu muốn.</li>
</ul>
<ul>Thành phần thứ 2 của KVM guest là storage; như đã nhắc ở trên, cái này có thể là một file trong hệ thống hoặc có thể là một volume managed với một logical volume manager (LVM) 
	<li>Sửa file cầu hình của một guest, sử dụng <i>virsh edit <Name of guest VM></i>, hệ thống sẽ mở file XML trong cửa sổ đang làm việc</li>
	<li>Xuất file cấu hình của guest, sử dụng lệnh <i>virsh dumpxml <Name of guest VM></i>, lệnh này sẽ dump file cấu hình XML ra STDOUT, bạn có thể chuyển nó vào file nếu muốn.</li>
</ul>

#### Tạo KVM guest
<ul> Có 02 cách để tạo một KVM guest
	<li>Tạo thủ công file XML mô tả guest, sử dụng lệnh <i>virsh define <Name of XML file></i> để import vào khai báo. Bạn có thể tạo file XML mới dựa trên file đã có và chỉ thay đổi
	một vài tham số</li>
	<li>Sử dụng libvirt-compatible tool như <i>virt-install</i> để tạo guest definition</li>
</ul>
<ul>Ở đây tạo nhanh một KVM guest sử dụng <i>virt-install</i>:
<pre>
virt-install --name vmname --ram 1024 --vcpus=1 \
--disk path=/var/lib/libvirt/images/vmname.img,size=20,bus=virtio \
--network bridge=ovsbr0 \
--cdrom /home/tannt/ubuntu-14.04.4-server-amd64.iso \
--graphics none --console pty,target_type=serial --hvm \
--os-variant ubuntutrusty --virt-type=kvm --os-type linux
</pre>
</ul>
<ul>Chi tiết các tham số của lệnh <i>virt-install</i> có thể tham khảo thêm tại <a href="https://linux.die.net/man/1/virt-install">Link này</a></ul>

## Tham khảo
<ul>http://blog.scottlowe.org/2012/08/17/installing-kvm-and-open-vswitch-on-ubuntu/</ul>
<ul>http://blog.scottlowe.org/2012/08/21/working-with-kvm-guests/</ul>
<ul>https://www.rivy.org/2014/04/install-a-kvm-host-on-ubuntu-14-04-trusty-tahr/</ul>
<ul></ul>
<ul></ul>
<ul>
	<li><i></i></li>
</ul>
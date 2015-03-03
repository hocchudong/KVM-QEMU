# KVM-QEMU
Thực hiện chức năng Migrate trong KVM-QEMU
## 1. Khái niệm:
KVM (Kernel-base virtual machine): là một mudule nằm trong nhân Linux để có thể tạo ra không gian cho các ứng dụng để các ứng dụng đó có thể chạy các tính với quyền lớn nhất.
Qemu: là một hypervisor dạng Paravirtualization nó tương tự như VMwate workstation 

Vậy KVM-QEMU là ảo hóa kết hợp QEMU với KVM theo kiểu QEMU sẽ móc nối với  mudule KVM trở thành dạng ảo hóa Full virtualization 

Kiến trúc của KVM-QEMU

<img class="image__pic js-image-pic" src="http://i.imgur.com/LDUJSNZ.png" alt="" id="screenshot-image">

## 2. Các tool để điều khiển KVM-Qemu
Bao gồm: 

+ virsh 
+ virt-manager
+ Openstack
+ ovirt
+ ...

Hình trên ta có thể hiểu: Đối với từng dạng ảo hóa như Kvm, Xen, .. sẽ có một tiến trình Libvirt chạy để điều khiển các dang ảo hóa và cung cấp những API để các tool như virsh, virt-manager, Openstack, ovirt có thể giao tiếp với KVM-Qemu thông qua livbirt

<img class="image__pic js-image-pic" src="http://i.imgur.com/c2Qn4V8.png" alt="" id="screenshot-image">

## 3. Chức năng của Migrate KVM-QEMU

### 3.1: Khái niệm

Migrate là chức năng được KVM-QEMU hỗ trợ, nó cho phép di chuyển các guest từ một host vật lý này sang host vật lý khác và không ảnh hướng để guest đang chạy cũng như dữ liệu bên trong nó

### 3.2 Vai trò

Migrate giúp cho nhà quản trị có thể di chuyển các guest trên host đi để phục vụ cho việc bảo trì và nâng cấp hệ thống, nó cũng giúp nhà quản trị nâng cao tính dự phòng, và cũng có thể làm nhiệm vụ load bandsing cho hệ thống khi một máy host quá tải

### 3.3 Cơ chế:
Migrate có 2 cơ chế:
+ Cơ chế Offline Migrate: là cơ chế cần phải tắt guest đi thực hiện việc di chuyển image và file xml của guest sang một host khác
Mô hình thuần túy của cơ chế Offline Migrate

<img class="image__pic js-image-pic" src="http://i.imgur.com/TbLqlOI.png" alt="" id="screenshot-image">


+ Cơ chế Live Migrate: đây là cơ chế di chuyển guest khi guest vẫn đang hoạt động, quá trình trao đổi diễn ra rất nhanh các phiên làm việc kết nối hầu như không cảm nhận được sự gián đoạn nào. Quá trình Live Migrate được diễn ra như sau: Bước đầu tiên của quá trình Live Migrate 1 ảnh chụp ban đầu của guest trên host1 được chuyển sang host2. Trong trường hợp người dùng đang truy cập tại host1 thì những sự thay đổi và hoạt động trên host1 vẫn diễn ra bình thường, tuy nhiên những thay đổi này sẽ được ghi nhận. Những thay đổi trên host1 được đồng bộ liên tục đến host2
Khi đã đồng bộ xong thì guest trên host1 sẽ offline và các phiên truy cập trên host1 được chuyển sang host2.

### 3.4 Lab

Thực hiện tính năng Migrate đối với cơ chế Live Migrate kết hợp với hệ thống chia sẻ file NFS

Ý tưởng của cơ chế này: Cần một Server Storage chia sẻ một thư mục để 2 host có thể móc mount vào thư mục đó

**a. Yêu cầu**

+ Cả hai host chạy KVM phải mở port TCP/IP
+ Hệ thống chia sẻ file phải cùng tên thư mục ở trên cả server-storage và client-storage (2 host chạy KVM)
+ Trong quá trình tạo guest trên host cần phải chọn chế độ Cache=none ( chọn chế độ này với mục đích các tiến trình trên guest sẽ không được lưu đệm trên Ram vật lý nên sẽ không bị mất thông tin khi Migrate sang host khác )

**b. Mô hình Lab**

<img class="image__pic js-image-pic" src="http://i.imgur.com/8wHeLvf.png" alt="" id="screenshot-image">

**c. Cài đặt**

*c.1: Xây dựng mô hình như trong hình vẽ*

*c.2: Cài đặt 2 host chạy KVM-QEMU và NFS*

Các bước được thực hiện trên 2 host cài đặt KVM-QEMU

+ Cài đặt KVM-QEMU:
```
aptitude -y install qemu-kvm libvirt-bin virtinst bridge-utils
```
+ Kích hoạt chế độ tạo vhost-net
```
 modprobe vhost_net 
```
```
 lsmod | grep vhost
```
```
echo vhost_net >> /etc/modules
```
+ Chỉnh sửa lại file interface để cấu hình Brigde network như sau

```
vi /etc/network/interface
```
```
The loopback network interface
auto lo
iface lo inet loopback

auto br0
iface br0 inet dhcp
bridge_ports eth0
bridge_fd 9
bridge_hello 2
bridge_maxage 12
bridge_stp off

auto eth0
iface eth0 inet manual
up ip link set dev $IFACE up
auto eth1
iface eth1 inet static
address 10.10.10.10 # doi voi host2 chinh thanh 10.10.10.20
netmask 255.255.255.0
```
+ Cài đặt virt-manager với mục đích quan sát
```
aptitude -y install virt-manager qemu-system hal
```
+ Cài đặt nfs client: [tham khao tai link sau](http://www.server-world.info/en/note?os=Ubuntu_14.04&p=nfs&f=2)

*c.3 Cài đặt NFS server*

Tham khảo tại link [server word](http://www.server-world.info/en/note?os=Ubuntu_14.04&p=nfs&f=1)

**d. Lap**

Đầu tiên tạo môt guest chạy trên host1. Thông tin về cách tạo guest trên host các bạn xem thêm bài viết của anh [Cao Ngọc Uy](https://github.com/caongocuy/Tao-image)

*d.1 Migrate dùng câu lệnh virsh*

+ Thực hiện câu lênh trên host1 ( chứa guest1 đang chạy )
```
virsh migrate --live <tên guest muốn migrate> qemu+ssh://<hostnam của đích chuyển đến>/system
```
VD: ` virsh migrate --live guest1 qemu+ssh://10.10.10.20/system `

Khi đó quan sát trên virt-manager sẽ thấy guest1 trên host1 sẽ di chuyển sang host2 mà vẫn đang ở trạng thái hoạt động thời gian downtime của guest1 là khá nhỏ

Ngoài tùy chọn --live. Còn thêm một số các tùy chọn khác như:

--live : tùy chọn chuyển trực tiếp guest khi đang chạy mà không làm tắt guest ( nếu không có tùy chọn này thì guest sẽ khởi động lại )

--persistent : tùy chọn chuyển máy ảo sang host mới mà khi tắt guest đó, guest sẽ không bị mất

--undefinesource : tùy chọn này sẽ xóa guest ở nguồn đi 

--suspend : tùy chọn sẽ tạm dừng máy ảo khi chuyển sang máy host mới

--unsafe : chuyển máy ngay cả trong chế độ không an toàn
 
 Ngoài những tùy chọn trên có 3 tùy chọn rất đặc biệt, cũng có thể nói là tính năng nâng cao hơn đối với việc Migrate 
 
 --direct : Sử dụng migrate trực tiếp host mà không cần 2 host đó phải sử dụng chung thư mục
 
 --p2p : Sử dụng cho việc Migrate peer-to-peer 
 
 --tunnelled : Sử dụng cơ chế tunnel để migrate các guest
 
 Để hiểu thêm cơ chế migrate đối với 3 tùy chọn này. Bạn có thể tham khảo tại [link](https://libvirt.org/migration.html)
 
Dưới đây là những thông tin tôi DOC được trong quá trình tìm hiểu KVM-QEMU. Hi vọng sẽ cung cấp được phần nào kiến thức basic cho các bạn mới tìm hiểu. Mọi thông tin thắc mắc các bạn có thể liên hệ với tôi qua skype `namptit307` để cùng thảo luận.
 

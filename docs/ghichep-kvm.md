# Hướng dẫn cài đặt và quản lý KVM 

## Hướng dẫn sử dụng KVM bằng Xming

- XMING là công cụ cho phép quản lý KVM thông qua X11, XMING được cài trên windows và kết hợp cùng với các ứng dụng ssh (putty, MobaXterm ...)

### Mô hình
- Sử dụng vmware workstation làm môi trường dựng lab. 
- Máy server: 
 - Ubuntu 14.04 64 bit, 2 NIC (eth0 để ra internet tả gói - sử dụng `Bridge` hoặc `NAT`, eth1 quản trị - hostonly).
 - Máy server cài các gói KVM, gói virt-manager để điều khiển máy ảo thông qua giao diện đồ họa.
 - Cài đặt Linux Bridge hoặc OpenvSwitch để ảo hóa network cho các máy ảo. Trong ví dụ này sử dụng Linux Bridge
 - Cài đặt các gói hỗ trợ X11 phía Server là: `xorg, openbox`
- Máy Client: 
 - Sử dụng hệ điều hành windows 
 - Cài đặt putty hoặc MobaXterm (ví dụ này dùng putty)
 - Máy này sẽ thực hiện điều khiển KVM thông qua giao diện đồ họa đã được cài trên phía máy chủ.

### Các bước thực hiện
### Phía server 
- Thực hiện cài đặt bằng tay hoặc bằng script (ví dụ này cài bằng script)
- Login vào máy chủ Ubuntu và thực hiện script với quyền root.
	```sh
	su -
	apt-get update
	wget https://raw.githubusercontent.com/hocchudong/KVM-QEMU/master/scripts/setup-kvm.sh
	```

- Tùy chọn: có thể sửa dòng 28 trong file ` /etc/ssh/sshd_config` để cho phép ssh bằng tài khoản `root` từ xa, dòng đó sửa thành dòng dưới
	```sh
	PermitRootLogin yes
	```

- Thực thi script
	```sh
	chmod +x setup-kvm.sh
	bash setup-kvm.sh
	```

- Ở scrit trên sẽ cài đặt các thành phần sau
 - Thành phần KVM để tạo và quản lý máy ảo
 - Thành phần đồ họa quản lý KVM 
 - Gói linux bridge để cung cấp cơ chế network ảo cho máy ảo.
 - Gói hỗ trợ X11 phía server (script sử dụng gói xorg và openbox là các gói nhỏ nhẹ và hỗ trợ GUI cho linux)

#### Phía client 

- Ví dụ này sử dụng putty để ssh tới máy chủ Ubuntu
- Nếu bạn dùng các ứng dụng hỗ trợ thao tác enable X11 sẵn thì không cần làm bước này và chỉ cần bước SSH

Bước 1: 
- Tải Xming tại địa chỉ sau https://sourceforge.net/projects/xming/
- Cài đặt Xming, trong quá trình cài để mặc định các tùy chọn.
- Khởi động xming sau khi cài

Bước 2: 
- Cấu hình putty để sử dụng được xming
- Khởi động putty và cấu hình để kích hoạt X11 phía client theo hình các thao tác: `Connection` => `SSH` => `X11` 
![Putty1](./images/img1.png)

Bước 3: 
- Thực hiện nhập IP của máy chủ Ubuntu vào mục `Secssion` trong putty
![Putty2](./images/img2.png)

- Login với tài khoản `root` (lưu ý, tính năng cho phép ssh bằng `root` phải được kích hoạt trước) và gõ lệnh dưới để khởi động công cụ quản lý KVM
	```sh
	virt-manager
	```

- Sẽ có màn hình thông báo của Xming được hiển thị ra, bắt đầu có thể sử dụng công cụ `virt-manager` để quản lý KVM

![virt-manage](./images/img3.png)


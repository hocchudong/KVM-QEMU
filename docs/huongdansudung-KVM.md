# Tài liệu hướng dẫn sử dụng KVM
- Yêu cầu: Đã cài đặt KVM và các công cụ hỗ trợ.

## Hướng dẫn sử dụng công cụ đồ họa 'virt-manager'


### Tạo máy ảo từ đầu

- Máy ảo sẽ được tạo từ file ISO

```sh
update sau
```

### Tạo máy ảo từ file images có sẵn (giống như file ghost)

Bước 1: Tải file img từ internet về
- Login vào máy chủ Ubuntu cài đặt KVM và thực hiện các lệnh sau
```sh
su -

cd /var/lib/libvirt/images/
wget 
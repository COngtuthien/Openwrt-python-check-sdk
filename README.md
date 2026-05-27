# Mock Project: Display Python 3.9 Version via C App — OpenWrt SDK x86_64

> **Package output:** `.apk` · **Build env:** Docker · **Target:** OpenWrt SDK x86_64

---

## 📌 Mục Tiêu

Xây dựng một chương trình C nhỏ dưới dạng OpenWrt package, có chức năng:

1. Kiểm tra hệ thống có `python3.9` hay không
2. Nếu có, chạy `python3.9 --version` và in version ra terminal
3. Ghi kết quả vào `/tmp/python_ver.log`
4. Test thật trong 2 Docker container — một có Python 3.9, một không có

> **Không cần Raspberry Pi, không cần cài OpenWrt lên máy thật.** Toàn bộ build và test chạy trong Docker container từ terminal Ubuntu.

---

## 🗺️ Mô Hình Hoạt Động

```
Ubuntu laptop terminal
│
├── make package
│   └── Docker container (OpenWrt SDK x86_64)
│       └── Build C app → sinh package .apk
│
└── make test-2-cases
    ├── Container python:3.9-slim   → có Python 3.9 → app chạy thành công
    └── Container debian:12-slim    → không có Python → app báo lỗi
```

---

## 📁 Cấu Trúc Project

```
openwrt-python-check-sdk/
├── Dockerfile.sdk           # Container build OpenWrt SDK
├── Dockerfile.runtime       # Container test: có Python 3.9
├── Dockerfile.no-python     # Container test: không có Python
├── Makefile                 # Điều khiển toàn bộ flow build & test
├── README.md
├── package/
│   └── check-python/
│       ├── Makefile         # OpenWrt package Makefile
│       └── src/
│           └── check_python.c   # Source code C
├── sdk/                     # OpenWrt SDK (tự động tải khi build)
└── output/                  # Output sau build
    ├── check-python-1.0-r1.apk
    └── check_python
```

---

## ⚙️ Yêu Cầu Hệ Thống

Cài các tool cần thiết trên Ubuntu:

```bash
sudo apt update
sudo apt install -y docker.io git make curl wget zstd
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker
```

Kiểm tra Docker, Git, Make:

```bash
docker --version
git --version
make --version
```



Nếu gặp lỗi **permission denied** với Docker socket:

```bash
sudo usermod -aG docker $USER
newgrp docker
docker run hello-world
```

---

## 🚀 Khởi Tạo Project

```bash
mkdir -p ~/openwrt-python-check-sdk
cd ~/openwrt-python-check-sdk

git init
git checkout -b feature/python-version-check

mkdir -p package/check-python/src
mkdir -p sdk output
```

---

## 📄 Đặt File Source Code

Sau khi tạo cấu trúc thư mục, đặt các file source code vào đúng vị trí:

| File | Đặt tại |
|------|---------|
| `check_python.c` | `package/check-python/src/check_python.c` |
| `Makefile` (OpenWrt package) | `package/check-python/Makefile` |
| `Dockerfile.sdk` | `./Dockerfile.sdk` |
| `Dockerfile.runtime` | `./Dockerfile.runtime` |
| `Dockerfile.no-python` | `./Dockerfile.no-python` |
| `Makefile` (root) | `./Makefile` |

> ✅ Sau khi đặt file xong, kiểm tra lại:
> ```bash
> ls -lR package/check-python/
> ls -l Dockerfile.* Makefile
> ```

---

## 🔧 Fix Permission (nếu cần)

Nếu từng build bằng Docker trước đó và gặp lỗi **Permission denied**, chạy:

```bash
sudo chown -R $USER:$USER ~/openwrt-python-check-sdk
```

---

## 🏗️ Build Package

```bash
cd ~/openwrt-python-check-sdk
make package
```

Lần đầu chạy sẽ tự động:
1. Build Docker image SDK
2. Tải OpenWrt SDK 25.12.4 (~vài trăm MB)
3. Compile C app bằng cross-compiler của SDK
4. Sinh package `.apk` và copy binary ra `output/`

✅ **Output mong đợi ở cuối:**

```
Generated package files:
bin/packages/x86_64/base/check-python-1.0-r1.apk

Built binary:
build_dir/target-x86_64_musl/check-python-1.0/.pkgdir/check-python/usr/bin/check_python

Generated APK:
-rw-r--r-- ... output/check-python-1.0-r1.apk

Copied runnable binary:
-rwxr-xr-x ... output/check_python
```

Kiểm tra output:

```bash
ls -lh output/
```

Expected:

```
check-python-1.0-r1.apk
check_python
```

---

## 🧪 Test Case 1: Container Có Python 3.9

```bash
make run
```

✅ **Output mong đợi:**

```
===== CASE 1: Container has Python 3.9 =====
Python check inside container:
/usr/local/bin/python3.9
Python 3.9.x

Running app:
Detected Python Version: 3.9.x
Log saved to: /tmp/python_ver.log

---- /tmp/python_ver.log ----
Detected Python Version: 3.9.x
```

---

## 🧪 Test Case 2: Container Không Có Python

```bash
make test-no-python
```

✅ **Output mong đợi:**

```
===== CASE 2: Container has no Python 3.9 =====
Python check inside container:
python3.9 not found
python3 not found

Running app:
Error: Python 3.9 not found

---- /tmp/python_ver.log ----
Error: Python 3.9 not found
```

---

## 🧪 Chạy Cả 2 Case Cùng Lúc

```bash
make test-2-cases
```

---

## 🔍 Inspect Build Output

```bash
make inspect
```

Hiển thị:
- Nội dung thư mục `output/`
- File `.apk` trong SDK
- Binary `check_python` trong `build_dir`

---

## 🗂️ Tóm Tắt Lệnh Make

| Lệnh | Chức năng |
|------|-----------|
| `make package` | Build package OpenWrt `.apk` |
| `make run` | Test Case 1: container có Python 3.9 |
| `make test-no-python` | Test Case 2: container không có Python |
| `make test-2-cases` | Chạy cả 2 case liên tiếp |
| `make inspect` | Xem chi tiết file build output |
| `make clean` | Xoá output build của package |
| `make distclean` | Xoá toàn bộ SDK và output |

---

## 🧹 Clean

Xoá output build:

```bash
make clean
```

Nếu gặp permission denied:

```bash
sudo chown -R $USER:$USER ~/openwrt-python-check-sdk
make clean
```

Xoá toàn bộ SDK để build lại từ đầu:

```bash
make distclean
make package   # sẽ tải lại SDK, hơi lâu
```

---



# Openwrt-python-check-sdk

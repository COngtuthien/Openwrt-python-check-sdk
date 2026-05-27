# Mock Project: Display Python 3.9 Version via C App — OpenWrt SDK x86_64

> **Package output:** `.apk` · **Build env:** Docker · **Target:** OpenWrt SDK x86_64

---

## 📌 Objective

Build a small C program as an OpenWrt package that:

1. Checks whether `python3.9` is available on the system
2. If found, runs `python3.9 --version` and prints the version to the terminal
3. Writes the result to `/tmp/python_ver.log`
4. Tests in 2 Docker containers — one with Python 3.9, one without

> **No Raspberry Pi needed. No need to install OpenWrt on a real machine.** All builds and tests run inside Docker containers from an Ubuntu terminal.

---

## 🗺️ How It Works

```
Ubuntu laptop terminal
│
├── make package
│   └── Docker container (OpenWrt SDK x86_64)
│       └── Build C app → generate .apk package
│
└── make test-2-cases
    ├── Container python:3.9-slim   → has Python 3.9 → app runs successfully
    └── Container debian:12-slim    → no Python     → app reports error
```

---

## 📁 Project Structure

```
openwrt-python-check-sdk/
├── Dockerfile.sdk           # Container for building with OpenWrt SDK
├── Dockerfile.runtime       # Test container: with Python 3.9
├── Dockerfile.no-python     # Test container: without Python
├── Makefile                 # Controls the entire build & test flow
├── README.md
├── package/
│   └── check-python/
│       ├── Makefile         # OpenWrt package Makefile
│       └── src/
│           └── check_python.c   # C source code
├── sdk/                     # OpenWrt SDK (auto-downloaded on build)
└── output/                  # Build output
    ├── check-python-1.0-r1.apk
    └── check_python
```

---

## ⚙️ System Requirements

Install the required tools on Ubuntu:

```bash
sudo apt update
sudo apt install -y docker.io git make curl wget zstd
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker
```

Verify Docker, Git, and Make:

```bash
docker --version
git --version
make --version
```

If you encounter a **permission denied** error with the Docker socket:

```bash
sudo usermod -aG docker $USER
newgrp docker
docker run hello-world
```

---

## 🚀 Project Initialization

```bash
mkdir -p ~/openwrt-python-check-sdk
cd ~/openwrt-python-check-sdk

git init
git checkout -b feature/python-version-check

mkdir -p package/check-python/src
mkdir -p sdk output
```

---

## 📄 Placing Source Files

After creating the directory structure, place source files in the correct locations:

| File | Location |
|------|----------|
| `check_python.c` | `package/check-python/src/check_python.c` |
| `Makefile` (OpenWrt package) | `package/check-python/Makefile` |
| `Dockerfile.sdk` | `./Dockerfile.sdk` |
| `Dockerfile.runtime` | `./Dockerfile.runtime` |
| `Dockerfile.no-python` | `./Dockerfile.no-python` |
| `Makefile` (root) | `./Makefile` |

> ✅ After placing the files, verify:
> ```bash
> ls -lR package/check-python/
> ls -l Dockerfile.* Makefile
> ```

---

## 🔧 Fix Permissions (if needed)

If you previously built with Docker and encounter **Permission denied** errors:

```bash
sudo chown -R $USER:$USER ~/openwrt-python-check-sdk
```

---

## 🏗️ Building the Package

```bash
cd ~/openwrt-python-check-sdk
make package
```

On the first run, this will automatically:
1. Build the SDK Docker image
2. Download OpenWrt SDK 25.12.4 (~several hundred MB)
3. Compile the C app using the SDK's cross-compiler
4. Generate the `.apk` package and copy the binary to `output/`

✅ **Expected output at the end:**

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

Verify the output:

```bash
ls -lh output/
```

Expected:

```
check-python-1.0-r1.apk
check_python
```

---

## 🧪 Test Case 1: Container With Python 3.9

```bash
make run
```

✅ **Expected output:**

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

## 🧪 Test Case 2: Container Without Python

```bash
make test-no-python
```

✅ **Expected output:**

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

## 🧪 Running Both Cases Together

```bash
make test-2-cases
```

---

## 🔍 Inspect Build Output

```bash
make inspect
```

Displays:
- Contents of the `output/` directory
- `.apk` files inside the SDK
- `check_python` binary in `build_dir`

---

## 🗂️ Make Command Summary

| Command | Description |
|---------|-------------|
| `make package` | Build OpenWrt `.apk` package |
| `make run` | Test Case 1: container with Python 3.9 |
| `make test-no-python` | Test Case 2: container without Python |
| `make test-2-cases` | Run both cases in sequence |
| `make inspect` | View detailed build output files |
| `make clean` | Remove package build output |
| `make distclean` | Remove entire SDK and all output |

---

## 🧹 Cleanup

Remove build output:

```bash
make clean
```

If you encounter permission denied:

```bash
sudo chown -R $USER:$USER ~/openwrt-python-check-sdk
make clean
```

Remove the entire SDK to rebuild from scratch:

```bash
make distclean
make package   # will re-download the SDK, takes a while
```

---

# openwrt-python-check-sdk

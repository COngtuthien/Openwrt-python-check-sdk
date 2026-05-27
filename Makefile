.RECIPEPREFIX := >

OPENWRT_VERSION := 25.12.4

SDK_FILE := openwrt-sdk-25.12.4-x86-64_gcc-14.3.0_musl.Linux-x86_64.tar.zst
SDK_URL := https://downloads.openwrt.org/releases/25.12.4/targets/x86/64/$(SDK_FILE)
SDK_DIR := sdk/openwrt-sdk-25.12.4-x86-64_gcc-14.3.0_musl.Linux-x86_64

SDK_IMAGE := openwrt-sdk-x86-builder
RUNTIME_IMAGE := check-python-runtime
NO_PYTHON_IMAGE := check-python-no-python

PKG_LOCAL_DIR := package/check-python
PKG_SDK_DIR := $(SDK_DIR)/package/check-python

BUILT_BIN := $(SDK_DIR)/build_dir/target-x86_64_musl/check-python-1.0/.pkgdir/check-python/usr/bin/check_python

.PHONY: all docker-build-sdk docker-build-runtime docker-build-no-python sdk prepare-package package run test-no-python test-2-cases inspect clean distclean status

all: package

docker-build-sdk:
> docker build \
> 	--build-arg UID=$$(id -u) \
> 	--build-arg GID=$$(id -g) \
> 	-f Dockerfile.sdk \
> 	-t $(SDK_IMAGE) .

docker-build-runtime:
> docker build -f Dockerfile.runtime -t $(RUNTIME_IMAGE) .

docker-build-no-python:
> docker build -f Dockerfile.no-python -t $(NO_PYTHON_IMAGE) .

sdk: docker-build-sdk
> docker run --rm \
> 	-v "$$(pwd)":/work \
> 	-w /work \
> 	$(SDK_IMAGE) \
> 	sh -c 'set -e; \
> 		mkdir -p sdk; \
> 		cd sdk; \
> 		if [ ! -d "openwrt-sdk-25.12.4-x86-64_gcc-14.3.0_musl.Linux-x86_64" ]; then \
> 			echo "Downloading OpenWrt SDK 25.12.4..."; \
> 			wget -O "$(SDK_FILE)" "$(SDK_URL)"; \
> 			tar --zstd -xf "$(SDK_FILE)"; \
> 		else \
> 			echo "OpenWrt SDK already exists."; \
> 		fi'

prepare-package: sdk
> rm -rf $(PKG_SDK_DIR)
> mkdir -p $(SDK_DIR)/package
> cp -a $(PKG_LOCAL_DIR) $(SDK_DIR)/package/

package: prepare-package
> docker run --rm \
> 	-v "$$(pwd)":/work \
> 	-w /work/$(SDK_DIR) \
> 	$(SDK_IMAGE) \
> 	sh -c 'set -e; \
> 		make defconfig; \
> 		grep -q "CONFIG_PACKAGE_check-python" .config || echo "CONFIG_PACKAGE_check-python=m" >> .config; \
> 		make defconfig; \
> 		grep "CONFIG_PACKAGE_check-python" .config; \
> 		make package/check-python/clean V=s || true; \
> 		make package/check-python/compile V=s; \
> 		echo ""; \
> 		echo "Generated package files:"; \
> 		find bin -type f -name "check-python-*.apk" -print; \
> 		echo ""; \
> 		echo "Built binary:"; \
> 		find build_dir -type f -path "*/.pkgdir/check-python/usr/bin/check_python" -print'
> mkdir -p output
> cp $$(find $(SDK_DIR)/bin -type f -name 'check-python-*.apk' -print -quit) output/
> cp $(BUILT_BIN) output/check_python
> chmod +x output/check_python
> echo ""
> echo "Generated APK:"
> ls -lh output/*.apk
> echo ""
> echo "Copied runnable binary:"
> ls -lh output/check_python

run: package docker-build-runtime
> docker run --rm \
> 	-v "$$(pwd)":/work \
> 	-v /tmp:/tmp \
> 	-w /work \
> 	$(RUNTIME_IMAGE) \
> 	sh -c 'set -e; \
> 		echo "===== CASE 1: Container has Python 3.9 ====="; \
> 		echo "Python check inside container:"; \
> 		command -v python3.9; \
> 		python3.9 --version; \
> 		echo ""; \
> 		echo "Running app:"; \
> 		./output/check_python; \
> 		echo ""; \
> 		echo "---- /tmp/python_ver.log ----"; \
> 		cat /tmp/python_ver.log'

test-no-python: package docker-build-no-python
> docker run --rm \
> 	-v "$$(pwd)":/work \
> 	-v /tmp:/tmp \
> 	-w /work \
> 	$(NO_PYTHON_IMAGE) \
> 	sh -c 'set -e; \
> 		echo "===== CASE 2: Container has no Python 3.9 ====="; \
> 		echo "Python check inside container:"; \
> 		command -v python3.9 || echo "python3.9 not found"; \
> 		command -v python3 || echo "python3 not found"; \
> 		echo ""; \
> 		echo "Running app:"; \
> 		./output/check_python || true; \
> 		echo ""; \
> 		echo "---- /tmp/python_ver.log ----"; \
> 		cat /tmp/python_ver.log'

test-2-cases: run test-no-python

inspect: package
> echo "Output directory:"
> ls -lh output
> echo ""
> echo "Generated package in SDK:"
> find $(SDK_DIR)/bin -type f -name "check-python-*.apk" -print
> echo ""
> echo "Built files:"
> find $(SDK_DIR)/build_dir -type f \( -name "check_python" -o -name "*check-python*" \) -print | head -50

status:
> git status
> echo ""
> echo "Output files:"
> ls -lh output || true

clean:
> rm -rf output
> rm -rf $(SDK_DIR)/build_dir/target-*/check-python* || true
> rm -rf $(SDK_DIR)/bin/packages/x86_64/base/check-python-*.apk || true

distclean:
> rm -rf sdk output

---
layout: default
title:  "Compile and upgrade source code of AV1 in or out of WebRTC"
date:   2022-05-30 18:31:33 +0800
categories: av1
---

# Abstract
It's about how to compile and upgrade source code of AV1 in or out of WebRTC.

# Build AV1 within WebRTC
## Current AV1 version in m91
v3.1.2

### Newest AV1 version of AV1
v3.3.0
```C++
#include "third_party/libaom/source/config/config/aom_version.h"
#define VERSION_MAJOR 3
#define VERSION_MINOR 3
#define VERSION_PATCH 0
#define VERSION_EXTRA "330-gee1ed1ccf"
#define VERSION_PACKED \
  ((VERSION_MAJOR << 16) | (VERSION_MINOR << 8) | (VERSION_PATCH))
#define VERSION_STRING_NOSP "3.3.0-330-gee1ed1ccf"
#define VERSION_STRING " 3.3.0-330-gee1ed1ccf"

```

## Sources of different platforms
### iOS
### android

## Build config
iOS/android/linux use the same build config.
```shell
if (is_nacl) {
  platform_include_dir = "source/config/linux/generic"
} else {
  if (is_ios && current_cpu == "arm") {
    os_category = current_os
  } else if (is_posix || is_fuchsia) {
    print("is_posix:",is_posix)
    # Should cover linux, fuchsia, mac, and the ios simulator.
    os_category = "linux"
  } else {  # This should only match windows.
    os_category = current_os
  }
  platform_include_dir = "source/config/$os_category/$cpu_arch_full"
  print("platform_include_dir:",platform_include_dir)
}

libaom_include_dirs = [
  "source/config",
  platform_include_dir,
  "source/libaom",
]

```

Actual `platform_include_dir` for building iOS
```shell
is_posix: true
platform_include_dir: source/config/linux/arm64
["source/config", "source/config/linux/arm64", "source/libaom"]
```

NOTE:Build config is generated on depend of platforms automatically.
## How to upgrade source code of AV1?
### Update third_party/libaom library
* Get specified repo of AV1 in original WebRTC repo
* Remove .git directories
* Copy and add to new branch of third_party/libaom

Example if you are a iOS developer.

At Mac machine
~~~
  # Checkout tag v3.3.0 from aom repo
  $ cd aom_source_dir
  $ git clone https://aomedia.googlesource.com/aom
  $ git checkout -b v3.3.0 v3.3.0
  
  # Copy source code to src/third_party/libaom
  $ cd src/third_party/libaom
  # Create a new branch 
  $ git checkout -b v3.3.0
  # Copy newst source code from aom_source_dir
  $ cd source
  $ cp -rf aom_source_dir/aom ./
  $ rm -rf libaom
  $ mv aom libaom
  # Commit newest code
  $ rm -rf libaom/.git  
  $ cd ..
  $ git add all files
  $ git commit

~~~

Now switch to linux machine
~~~
  # Modify third_party/.gitmodules,change branch of libao to v3.3.0
  # Update third_party/libaom
  $ git_update_all_submodules.sh
  # Run cmake_update.sh to generate build config files.
  $ cd third_party/libaom
  $ ./cmake_update.sh
  # Commit and push new generated config files to remote
~~~

Switch back to Mac machine,update third_party/libaom
~~~
  $ git_update_all_submodules.sh
~~~
### Change branch name of libaom in third_party/.gitmodules
```shell
#include "third_party/.gitmodules"
[submodule "libaom"]
	path = libaom
	url = git@code.xxx.com:Third-Party/libaom.git
	branch = v3.3.0

```

### Notify members of RTC updating all git sub modules
By run
~~~
  $  git_update_all_submodules.sh
~~~
### Changes of binary size
Use v2.0.2
> Current size of out/ios/obj/sdk/librtc_sdk_static_objc.a is:336M,size in bytes:352037976

Use v3.2.0

Use v3.3.0
> Current size of out/ios/obj/sdk/librtc_sdk_static_objc.a is:337M,size in bytes:353386320

NOTE:size of binary is tested with building ios demo.
## Issues 

### Run `third_party/libaom/roll_dep.py` failed
~~~
➜  src git:(main) ✗ roll_dep.py  --log-limit 20 --roll-to 87682566cba91bf391c2aeb8a827252b7f1c7162 --ignore-dirty-tree -r klaus@xxx.com src/third_party/libaom/source/libaom
Traceback (most recent call last):
  File "/Users/klaus/dev/src/webrtc/google_src/src/third_party/depot_tools/gclient.py", line 108, in <module>
    import gclient_scm
  File "/Users/klaus/dev/src/webrtc/google_src/src/third_party/depot_tools/gclient_scm.py", line 29, in <module>
    import gerrit_util
  File "/Users/klaus/dev/src/webrtc/google_src/src/third_party/depot_tools/gerrit_util.py", line 16, in <module>
    import httplib2
ImportError: No module named httplib2
Traceback (most recent call last):
  File "/Users/klaus/dev/src/webrtc/google_src/src/third_party/depot_tools/roll_dep.py", line 298, in <module>
    sys.exit(main())
  File "/Users/klaus/dev/src/webrtc/google_src/src/third_party/depot_tools/roll_dep.py", line 238, in main
    gclient_root = gclient(['root'])
  File "/Users/klaus/dev/src/webrtc/google_src/src/third_party/depot_tools/roll_dep.py", line 108, in gclient
    return check_output([sys.executable, GCLIENT_PATH] + args).strip()
  File "/Users/klaus/dev/src/webrtc/google_src/src/third_party/depot_tools/roll_dep.py", line 55, in check_output
    return subprocess2.check_output(*args, **kwargs).decode('utf-8')
  File "/Users/klaus/dev/src/webrtc/google_src/src/third_party/depot_tools/subprocess2.py", line 258, in check_output
    return check_call_out(args, stdout=PIPE, **kwargs)[0]
  File "/Users/klaus/dev/src/webrtc/google_src/src/third_party/depot_tools/subprocess2.py", line 221, in check_call_out
    returncode, args, kwargs.get('cwd'), out[0], out[1])
subprocess2.CalledProcessError: Command '/System/Library/Frameworks/Python.framework/Versions/2.7/Resources/Python.app/Contents/MacOS/Python /Users/klaus/dev/src/webrtc/google_src/src/third_party/depot_tools/gclient.py root' returned non-zero exit status 1
~~~

Install missed modules
~~~
  $ pip3 install six --upgrade
  $ pip3 install httplib2 --upgrade
~~~

Run as Python3 as Python2 is deprecated soon,pip is not supported.
~~~
➜  src git:(main) ✗ python3 third_party/depot_tools/roll_dep.py  --log-limit 20 --roll-to 87460cef80fb03def7d97df1b47bad5432e5e2e4 --ignore-dirty-tree -r klaus@xxx.com src/third_party/libaom/source/libaom
src/third_party/libaom/source/libaom: Rolling from 87682566cb to 87460cef80
Commit message:
    Roll src/third_party/libaom/source/libaom/ 87682566c..87460cef8 (808 commits)

    https://aomedia.googlesource.com/aom.git/+log/87682566cba9..87460cef80fb

    $ git log 87682566c..87460cef8 --date=short --no-merges --format='%ad %ae %s'
    2022-02-14 wtc Replace AOM_EXT_PART_ABI_VERSION with old value
    2022-02-04 wtc Document more codec controls added in v3.3.0
    2021-12-20 jzern reconinter_enc: quiet -Wstringop-overflow warnings
    2021-12-21 sanampudi.venkatarao Correct the referencing of an argument search_sites
    2021-12-20 jzern quiet -Warray-parameter warnings
    2022-01-28 fgalligan Update CHANGELOG,CMakeLists.txt for v3.3.0
    2022-01-27 fgalligan aomdx.h: Normalize controls to enum order.
    2022-01-26 fgalligan aomdx.h: Normalize codec control comments
    2022-01-28 fgalligan electric-sky: Update AUTHORS
    2022-01-27 wtc Correct the parameter types for three control IDs
    (...)
    2021-05-22 wtc Do not include "common/tools_common.h"
    2021-05-22 wtc Don't include the "common/tools_common.h" header
    2021-05-21 mudassir.galaganath Extend prune_sub_8x8_partition_level for speed 5
    2021-05-19 mudassir.galaganath Reduce entropy cost update frequency for mode
    2021-04-20 sdeng Enable tune=butteraugli in all-intra mode
    2021-05-10 sdeng Fix CONFIG_TUNE_VMAF build with -DBUILD_SHARED_LIBS=1
    2021-04-13 sdeng Add color range detection in tune=butteraugli mode
    2021-03-31 wtc Declare set_mb_butteraugli_rdmult_scaling static
    2021-04-20 sdeng Add libjxl to pkg_config if enabled
    2021-05-03 sdeng Fix vmaf model initialization error when not set to tune=vmaf

    Created with:
      roll-dep src/third_party/libaom/source/libaom
    R=klaus@xxx.com

Run:
  git cl upload --send-mail
~~~

Install pip with Python2.7 failed.
~~~
   ~ sudo python -m ensurepip --upgrade
   Password:
   /System/Library/Frameworks/Python.framework/Versions/2.7/Extras/lib/python/OpenSSL/crypto.py:14: CryptographyDeprecationWarning: Python 2 is no longer supported by the Python core team. Support for it is now deprecated in cryptography, and will be removed in the next release.
     from cryptography import utils, x509
   DEPRECATION: Python 2.7 will reach the end of its life on January 1st, 2020. Please upgrade your Python as Python 2.7 won't be maintained after that date. A future version of pip will drop support for Python 2.7. More details about Python 2 support in pip, can be found at https://pip.pypa.io/en/latest/development/release-process/#python-2-support
   WARNING: The directory '/Users/klaus/Library/Caches/pip/http' or its parent directory is not owned by the current user and the cache has been disabled. Please check the permissions and owner of that directory. If executing pip with sudo, you may want sudo's -H flag.
   WARNING: The directory '/Users/klaus/Library/Caches/pip' or its parent directory is not owned by the current user and caching wheels has been disabled. check the permissions and owner of that directory. If executing pip with sudo, you may want sudo's -H flag.
   Looking in links: /tmp/tmpDMer48
   Collecting setuptools
   Collecting pip
   Installing collected packages: setuptools, pip
     Found existing installation: setuptools 41.0.1
       Uninstalling setuptools-41.0.1:
   ERROR: Could not install packages due to an EnvironmentError: [Errno 1] Operation not permitted: '/private/tmp/pip-uninstall-upmUSo/easy_install.py'
~~~

### Run `cmake_update.sh` failed
To genenrate `config` for libaom,everytime we update the source code ,`cmake_update.sh` must be called.
Run at ubuntu and plenty of compilers must be installed firstly.
~~~
   $ sudo apt-get install -y yasm
   $ sudo apt-get install gcc-arm-linux-gnueabihf
   $ sudo apt-get install g++-arm-linux-gnueabihf
   $ sudo apt-get install gcc-aarch64-linux-gnu
   $ sudo apt-get install g++-aarch64-linux-gnu
~~~

Run successfully
~~~
   远端guding ➜  libaom git:(add2722) ✗ ./cmake_update.sh
   Generate linux/generic config files.
   Generate linux/ia32 config files.
   Generate linux/x64 config files.
   Generate win/ia32 config files.
   Generate win/x64 config files.
   Generate linux/arm config files.
   Generate linux/arm-neon config files.
   Generate linux/arm-neon-cpu-detect config files.
   Generate linux/arm64 config files.
   Generate ios/arm-neon config files.
   Generate ios/arm64 config files.
   Generate win/arm64 config files.
   
   README.chromium updated with:
   Date: Tuesday July 20 2021
   Commit: add2722e5036d89aa26a9196edafec5708805bb3
   WARNING: Your metrics.cfg file was invalid or nonexistent. A new one will be created.
   Command "git merge-base HEAD refs/remotes/origin/master" failed.
   
   ERROR: 'git cl format' failed. Please run 'git cl format' manually.
~~~
### Encode performance get worser when upgraded to v3.3.0 on android platform.
When upgrade libaom to v3.3.0 vesion,performance of encode get worser.encode time is twice than the previous version.

Relative issues that I send to libaom or WebRTC
[Issue 3265: Encoding speed get longer when value of aom_codec_enc_cfg_t.g_threads increased](https://bugs.chromium.org/p/aomedia/issues/detail?id=3265)

[Issue 3266: The encoding performance is not improved distinctly when upgrading from v2.0.2 to v3.3.0](https://bugs.chromium.org/p/aomedia/issues/detail?id=3266)

[Issue 13951: Encoding speed(AV1) get to be much slower on Android platform when upgrading libaom from v2.0.2 to v3.3.0](https://bugs.chromium.org/p/webrtc/issues/detail?id=13951#makechanges)
# Build AV1 seperately out of WebRTC
## Configuration

See [README.md](https://aomedia.googlesource.com/aom/)

~~~
  $ mkdir aom_build
  $ cd aom_build
  $ cmake -DCMAKE_INSTALL_PREFIX="/usr/local" -DCMAKE_BUILD_TYPE=Release ../aom
  $ make install
~~~

RTC-only build
~~~
   $ cmake -DCMAKE_BUILD_TYPE=Release -DCONFIG_REALTIME_ONLY=1 ../aom
~~~

* -DCMAKE_INSTALL_PREFIX="/usr/local" ,so compiled products will install to "/usr/local" dir.

~~~
   [100%] Built target lightfield_tile_list_decoder
   Install the project...
   -- Install configuration: "Release"
   -- Installing: /usr/local/include/aom/aom.h
   -- Installing: /usr/local/include/aom/aom_codec.h
   -- Installing: /usr/local/include/aom/aom_frame_buffer.h
   -- Installing: /usr/local/include/aom/aom_image.h
   -- Installing: /usr/local/include/aom/aom_integer.h
   -- Installing: /usr/local/include/aom/aom_decoder.h
   -- Installing: /usr/local/include/aom/aomdx.h
   -- Installing: /usr/local/include/aom/aomcx.h
   -- Installing: /usr/local/include/aom/aom_encoder.h
   -- Installing: /usr/local/include/aom/aom_external_partition.h
   -- Installing: /usr/local/lib/pkgconfig/aom.pc
   -- Installing: /usr/local/lib/libaom.a
   -- Installing: /usr/local/bin/aomdec
   -- Installing: /usr/local/bin/aomenc
~~~

We can check the accepted parameters of av1 library by:
~~~
  $ aomenc --help
~~~

### All  build configs from cmake
~~~
   $ cmake ../aom -LAH
~~~
## Build FFmpeg supporting AV1

See [build-ffmpeg-av1-svt](https://www.iiwnz.com/build-ffmpeg-av1-svt/)

Scipts for configuring ffmpeg with av1
~~~
   $ ./configure  --prefix=/usr/local --enable-gpl --enable-nonfree --enable-libass --enable-ffplay \
   --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame \
   --enable-libtheora --enable-libvorbis --enable-libvpx --enable-libx264 --enable-libx265 --enable-libopus --enable-libxvid \
   --enable-libaom --samples=fate-suite --extra-cflags=-I/usr/local/Cellar/sdl2/2.0.12_1/include/SDL2 --extra-ldflags=-L/usr/local/Cellar/sdl2/2.0.12_1/lib
~~~

~~~
  $  cd ffmpeg
  $  ./confiure  with params above
  $  make install
~~~


## Use FFmpeg processing AV1

### Convert a mp4 to mkv using av1 codec
~~~
  $ ffmpeg -i Samsung_Demo_Video.mp4 -c:v libaom-av1 -crf 30 -cpu-used 8 -row-mt 1  -usage 1 -threads 8 -b:v 2M av1_test.mkv
~~~

The encoding speed is really slow if these options not set
* -usage
* -cpu-used
* -row-mt
* -threads

### Convert a mp4 to mkv using h264 codec
~~~
   $ ffmpeg -i Samsung_Demo_Video.mp4 -c:v h264 -b:v 200K av1_test_h264.mkv
~~~
### Merge two videos to one video file

# Test
## Unit test
### Enable encoder performance test
~~~
  $ cd aom_build
  $ cmake -DCONFIG_REALTIME_ONLY=1  -DCONFIG_INTERNAL_STATS=1  -DENABLE_ENCODE_PERF_TESTS=1 ../aom
~~~
### Run one testcase
~~~
➜  aom_build ./test_libaom --gtest_filter=AV1CommonInt.TestGetTxSize --gtest_output=xml
Note: Google Test filter = AV1CommonInt.TestGetTxSize
[==========] Running 1 test from 1 test suite.
[----------] Global test environment set-up.
[----------] 1 test from AV1CommonInt
[ RUN      ] AV1CommonInt.TestGetTxSize
[       OK ] AV1CommonInt.TestGetTxSize (0 ms)
[----------] 1 test from AV1CommonInt (0 ms total)

[----------] Global test environment tear-down
[==========] 1 test from 1 test suite ran. (0 ms total)
[  PASSED  ] 1 test.
~~~

### Run one testsuite
### List testcases
~~~
➜  aom_build ./test_libaom --gtest_list_tests|grep EndtoEndPSNRTest
  EndtoEndPSNRTest/0  # GetParam() = (0x10a5501b0, TestVideoParam { filename:park_joy_90p_8_420.y4m input_bit_depth:8 fmt:258 bit_depth:8 profile:0 }, 5, 0, 1, 1)
  EndtoEndPSNRTest/1  # GetParam() = (0x10a5501b0, TestVideoParam { filename:park_joy_90p_8_420.y4m input_bit_depth:8 fmt:258 bit_depth:8 profile:0 }, 5, 3, 1, 1)
  EndtoEndPSNRTest/2  # GetParam() = (0x10a5501b0, TestVideoParam { filename:park_joy_90p_8_420.y4m input_bit_depth:8 fmt:258 bit_depth:8 profile:0 }, 6, 0, 1, 1)
  EndtoEndPSNRTest/3  # GetParam() = (0x10a5501b0, TestVideoParam { filename:park_joy_90p_8_420.y4m input_bit_depth:8 fmt:258 bit_depth:8 profile:0 }, 6, 3, 1, 1)
  EndtoEndPSNRTest/4  # GetParam() = (0x10a5501b0, TestVideoParam { filename:park_joy_90p_8_420.y4m input_bit_depth:8 fmt:258 bit_depth:8 profile:0 }, 7, 0, 1, 1)
  EndtoEndPSNRTest/5  # GetParam() = (0x10a5501b0, TestVideoParam { filename:park_joy_90p_8_420.y4m input_bit_depth:8 fmt:258 bit_depth:8 profile:0 }, 7, 3, 1, 1)
  EndtoEndPSNRTest/6  # GetParam() = (0x10a5501b0, TestVideoParam { filename:park_joy_90p_8_420.y4m input_bit_depth:8 fmt:258 bit_depth:8 profile:0 }, 8, 0, 1, 1)
  EndtoEndPSNRTest/7  # GetParam() = (0x10a5501b0, TestVideoParam { filename:park_joy_90p_8_420.y4m input_bit_depth:8 fmt:258 bit_depth:8 profile:0 }, 8, 3, 1, 1)
  EndtoEndPSNRTest/8  # GetParam() = (0x10a5501b0, TestVideoParam { filename:park_joy_90p_8_420.y4m input_bit_depth:8 fmt:258 bit_depth:8 profile:0 }, 9, 0, 1, 1)
  EndtoEndPSNRTest/9  # GetParam() = (0x10a5501b0, TestVideoParam { filename:park_joy_90p_8_420.y4m input_bit_depth:8 fmt:258 bit_depth:8 profile:0 }, 9, 3, 1, 1)
~~~
## Example test
~~~
  $ cd aom_build/examples
  $ ./svc_encoder_rtc front_camera_720p_quick_motion.y4m -o front_camera_720p_quick_motion.ivf  --speed=9 --width=720 --height=1280  --spatial-layers=1 --temporal-layers=1 --threads=6 --aqmode=0 --bit-depth=8 --target-bitrate=875 --bitrates=875
~~~

## Encoder test

rtc_encode.sh
```shell
#!/bin/bash
#
# Copyright (c) 2016, Alliance for Open Media. All rights reserved
#
# This source code is subject to the terms of the BSD 2 Clause License and
# the Alliance for Open Media Patent License 1.0. If the BSD 2 Clause License
# was not distributed with this source code in the LICENSE file, you can
# obtain it at www.aomedia.org/license/software. If the Alliance for Open
# Media Patent License 1.0 was not distributed with this source code in the
# PATENTS file, you can obtain it at www.aomedia.org/license/patent.
#
# Author: jimbankoski@google.com (Jim Bankoski)

if [[ $# -ne 2 ]]; then
  echo "Encodes a file using rtc settings"
  echo "  Usage:    be [FILE] [BITRATE]"
  echo "  Example:  be akiyo_cif.y4m 200"
  exit
fi

f=$1  # file is first parameter
b=$2  # bitrate is second parameter

  # do 1-pass rtc encode
  aomenc \
    $f \
    -o $f-$b.av1.webm \
    -p 1 \
    --pass=1 \
    --fpf=$f.fpf \
    --rt \
    --profile=0 \
    --threads=6 \
    --cpu-used=9 \
    --bit-depth=8 \
    --lag-in-frames=0 \
    --end-usage=cbr \
    --min-q=0 \
    --max-q=63 \
    --target-bitrate=$b \
    --undershoot-pct=50 \
    --overshoot-pct=50 \
    --buf-sz=1000 \
    --buf-initial-sz=600 \
    --buf-optimal-sz=600 \
    --buf-sz=1000 \
    --enable-cdef=2 \
    --enable-tpl-model=0 \
    --deltaq-mode=0 \
    --enable-order-hint=0 \
    --aq-mode=3 \
    --max-intra-rate=300 \
    --coeff-cost-upd-freq=3 \
    --mode-cost-upd-freq=3 \
    --mv-cost-upd-freq=3 \
    --dv-cost-upd-freq=3 \
    --row-mt=1 \
    --tile-columns=6 \
    --tile-rows=6 \
    --enable-obmc=0 \
    --noise-sensitivity=0 \
    --enable-global-motion=0 \
    --enable-warped-motion=0 \
    --enable-ref-frame-mvs=0 \
    --sb-size=64 \
    --enable-cfl-intra=0 \
    --enable-smooth-intra=0 \
    --enable-filter-intra=0 \
    --enable-angle-delta=0 \
    --use-intra-default-tx-only=1 \
    --loopfilter-control=2 \
    --cdf-update-mode=1


```

### v3.0.0~ vs v3.3.0 RTC encode comparision
M91 used v3.0.0~v3.1.0
~~~
$ git tag --contains <commit>
~~~

Result of v3.0.0~v3.1.0
Result of v3.3.0

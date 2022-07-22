---
layout: default
title: "How to build and run unit test of WebRTC"
date: 2022-07-15 12:54:09 +0800
categories: [webrtc,unittest]
---

# Abstract

This document describes that how to build and run unit test of WebRTC for all platforms
- macOS platform.
- iOS
- Android

# Build and run unit test for macOS

## Build WebRTC for macOS with unit tests
Firstly,we need building WebRTC with all unit tests.
### Set ENV PATH for gn/ninja
depot_tools is located at src/third_party/depot_tools,export this path to your .zshrc(if using Z shell) or .bashrc(if using bash shell).
```shell
export PATH="/root_path_of_src/src/third_party/depot_tools:$PATH"
```

### Do gn generation with rtc_include_tests=true
```shell
gn gen out/mac --args='target_os="mac" target_cpu="x64" use_xcode_clang=false  is_debug=true treat_warnings_as_errors=false rtc_include_tests=true' --ide=xcode
ninja -C out/mac
```

or removed `use_xcode_clang`,it's removed in webrtc now.

```shell
gn gen out/mac --args='target_os="mac" target_cpu="x64" is_debug=true treat_warnings_as_errors=false rtc_include_tests=true enable_libaom=true' --ide=xcode
ninja -C out/mac
```

- Add args `rtc_include_tests=true` to enable building all tests.
- Add args `treat_warnings_as_errors=false` ,as there may be compile warnings in the files of unit tests.

**Note:** if we don't have `python`,and only have `python3`(it happens at macOS Monterey 12.4,from this version,Apple deleted built-in `python2.x`),we could add `--script-executable=/usr/local/bin/python3` to specify the python executable. 
```shell
gn gen out/mac --args='target_os="mac" target_cpu="x64" is_debug=true treat_warnings_as_errors=false rtc_include_tests=true enable_libaom=true' --ide=xcode --script-executable=/usr/local/bin/python3
```

### Use ninja to build all targets generated by gn
```shell
ninja -C out/mac
```

## Run unit tests for macOS
All the unit tests are compiled to several executables.
If we want to run a test named "X",firstly,we need know that which executable contains this unit test.

### Find out executable containing the target unit test.
For exmaple ,if we want to run a unit test of `video/stream_synchronization_unittest.cc`.
1. Find the `rtc_library` target that contains file name `stream_synchronization_unittest.cc` in `BUILD.gn` file.
```gn
  rtc_library("video_tests") {
    testonly = true

    defines = []
    sources = [
      "stream_synchronization_unittest.cc",
    ]
  }
```

2. Find the runnable target `rtc_test` by `rtc_library` target name,as the `rtc_test` target depends on the `rtc_library` target.
```gn
  rtc_test("video_engine_tests") {
    testonly = true
    deps = [
      "audio:audio_tests",

      # TODO(eladalon): call_tests aren't actually video-specific, so we
      # should move them to a more appropriate test suite.
      "call:call_tests",
      "call/adaptation:resource_adaptation_tests",
      "test:test_common",
      "test:test_main",
      "test:video_test_common",
      "video:video_tests",
      "video/adaptation:video_adaptation_tests",
    ]
    data = video_engine_tests_resources
    if (is_android) {
      use_default_launcher = false
      deps += [
        "//build/android/gtest_apk:native_test_instrumentation_test_runner_java",
        "//testing/android/native_test:native_test_java",
        "//testing/android/native_test:native_test_support",
      ]
      shard_timeout = 900
    }
    if (is_ios) {
      deps += [ ":video_engine_tests_bundle_data" ]
    }
  }
```

Now we know the executable name which contains the target unit tests wroten in `video/stream_synchronization_unittest.cc`.

### Run unit test suite.

More details please see [chromium:running-tests](https://www.chromium.org/developers/testing/running-tests)


For example,run test suite `StreamSynchronizationTest`,which located at `src/video/`.

```shell
➜  mac git:(main) ✗ ./video_engine_tests --gtest_filter='StreamSynchronizationTest*'
(field_trial.cc:141): Setting field trial string:
Note: Google Test filter = StreamSynchronizationTest*
[==========] Running 17 tests from 1 test suite.
[----------] Global test environment set-up.
[----------] 17 tests from StreamSynchronizationTest
[ RUN      ] StreamSynchronizationTest.NoDelay
[       OK ] StreamSynchronizationTest.NoDelay (0 ms)
[ RUN      ] StreamSynchronizationTest.VideoDelayed
[       OK ] StreamSynchronizationTest.VideoDelayed (0 ms)
[ RUN      ] StreamSynchronizationTest.AudioDelayed
[       OK ] StreamSynchronizationTest.AudioDelayed (0 ms)
[ RUN      ] StreamSynchronizationTest.NoAudioIncomingUnboundedIncrease
[       OK ] StreamSynchronizationTest.NoAudioIncomingUnboundedIncrease (1 ms)
[ RUN      ] StreamSynchronizationTest.BothDelayedVideoLater
[       OK ] StreamSynchronizationTest.BothDelayedVideoLater (0 ms)
[ RUN      ] StreamSynchronizationTest.BothDelayedVideoLaterAudioClockDrift
[       OK ] StreamSynchronizationTest.BothDelayedVideoLaterAudioClockDrift (0 ms)
[ RUN      ] StreamSynchronizationTest.BothDelayedVideoLaterVideoClockDrift
[       OK ] StreamSynchronizationTest.BothDelayedVideoLaterVideoClockDrift (0 ms)
[ RUN      ] StreamSynchronizationTest.BothDelayedAudioLater
[       OK ] StreamSynchronizationTest.BothDelayedAudioLater (0 ms)
[ RUN      ] StreamSynchronizationTest.BothDelayedAudioClockDrift
[       OK ] StreamSynchronizationTest.BothDelayedAudioClockDrift (0 ms)
[ RUN      ] StreamSynchronizationTest.BothDelayedVideoClockDrift
[       OK ] StreamSynchronizationTest.BothDelayedVideoClockDrift (0 ms)
[ RUN      ] StreamSynchronizationTest.BothEquallyDelayed
[       OK ] StreamSynchronizationTest.BothEquallyDelayed (0 ms)
[ RUN      ] StreamSynchronizationTest.BothDelayedAudioLaterWithBaseDelay
[       OK ] StreamSynchronizationTest.BothDelayedAudioLaterWithBaseDelay (0 ms)
[ RUN      ] StreamSynchronizationTest.BothDelayedAudioClockDriftWithBaseDelay
[       OK ] StreamSynchronizationTest.BothDelayedAudioClockDriftWithBaseDelay (0 ms)
[ RUN      ] StreamSynchronizationTest.BothDelayedVideoClockDriftWithBaseDelay
[       OK ] StreamSynchronizationTest.BothDelayedVideoClockDriftWithBaseDelay (0 ms)
[ RUN      ] StreamSynchronizationTest.BothDelayedVideoLaterWithBaseDelay
[       OK ] StreamSynchronizationTest.BothDelayedVideoLaterWithBaseDelay (0 ms)
[ RUN      ] StreamSynchronizationTest.BothDelayedVideoLaterAudioClockDriftWithBaseDelay
[       OK ] StreamSynchronizationTest.BothDelayedVideoLaterAudioClockDriftWithBaseDelay (0 ms)
[ RUN      ] StreamSynchronizationTest.BothDelayedVideoLaterVideoClockDriftWithBaseDelay
[       OK ] StreamSynchronizationTest.BothDelayedVideoLaterVideoClockDriftWithBaseDelay (0 ms)
[----------] 17 tests from StreamSynchronizationTest (5 ms total)

[----------] Global test environment tear-down
[==========] 17 tests from 1 test suite ran. (5 ms total)
[  PASSED  ] 17 tests.
```

**Note:** Using the single quotes arround the value of `--gtest_fileter`,otherwise command will failed with error
```shell
➜  mac git:(main) ✗ ./video_engine_tests --gtest_filter=StreamSynchronizationTest*
zsh: no matches found: --gtest_filter=StreamSynchronizationTest*
```

### Run specified unit test
Sometimes ,we just need running a specified unit test to test our feature as quickly as possible.
For example,run speicifed unit test named `StreamSynchronizationTest.NoDelay` in test suite `StreamSynchronizationTest`,which located at `src/video/`.

```shell
➜  mac git:(main) ✗ ./video_engine_tests --gtest_filter='StreamSynchronizationTest.NoDelay'
(field_trial.cc:141): Setting field trial string:
Note: Google Test filter = StreamSynchronizationTest.NoDelay
[==========] Running 1 test from 1 test suite.
[----------] Global test environment set-up.
[----------] 1 test from StreamSynchronizationTest
[ RUN      ] StreamSynchronizationTest.NoDelay
[       OK ] StreamSynchronizationTest.NoDelay (0 ms)
[----------] 1 test from StreamSynchronizationTest (0 ms total)

[----------] Global test environment tear-down
[==========] 1 test from 1 test suite ran. (0 ms total)
[  PASSED  ] 1 test.
```

### Run unit test from Xcode
We can also run unit tests from Xcode.

1. select the `rtc_test` target which we want to run in Xcode
![run_unit_test_from_xcode](/image/run_unit_test_from_xcode.jpg)
2. if we want to run a specific unit test,we need `Edit Scheme` to add `Arguments` for the target.
![add_arguments_for_unit_test_in_xcode](/image/add_arguments_for_unit_test_in_xcode.jpg)

How to make Xcode supporting debug unit test ?
```shell
raceback (most recent call last):
  File "<input>", line 1, in <module>
ModuleNotFoundError: No module named 'lldbinit'
```

# Build and run unit test for iOS
TBC
# Build and run unit test for android
TBC
# Copyright notice
All Rights Reserved.Any reprint/reproduce/redistribution of this article MUST indicate the source. 
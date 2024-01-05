---
layout: default
title:  "Poor performance is observed at android platform with the newest AV1 version in WebRTC."
date:   2022-05-29 18:31:33 +0800
categories: av1
---

# Abstract
About processing the issue that poor performance is observed at android platform with the newest AV1 version in WebRTC.
# Try to make compile success with newest WebRTC souce code.
## Build commnds
~~~
  $ gn gen out/arm_test --args='target_os="android" target_cpu="arm" is_debug=false rtc_include_tests=false enable_libaom=true'
  $ ninja -C out/arm_test AppRTCMobile
~~~

Error happened
![python3_syntax_error](/image/python_syntax_error.jpg)

Verson of python3(3.5.2) is too low to support these new syntax.We need udpate python3 to 3.6 or higher.

[install-python3.6-on-ubuntu-16.04-LTS](https://alexzl5.github.io/install-python3.6-on-ubuntu-16.04-LTS/)

[install python 3.6 on ubuntu 16.04](https://moreless.medium.com/install-python-3-6-on-ubuntu-16-04-28791d5c2167)

After installed 3.6 from source code, another error
![python_dataclasses_not_found](/image/python_dataclasses_not_found.jpg)

Fix this by installing python3.9.9 from souce code instead.

# Optimize AppRTCMobile to support testing AV1
Optimization did to the android official demo AppRTCMobile
* For branch m91,make it support AV1 codec
* Make it supporting file video capturer,and use "ConferenceMotion_1280_720_50.y4m" as the inputed source file.
* Use degradationPreference mode 'RtpParameters.DegradationPreference.MAINTAIN_RESOLUTION;'
* Disable video adaptation by disable VideoQuality/EncoderUsage
* Calculate average encode ms from RTCStatsReport
* Set max bitrate to 875Kpbs.
* For branch main ,make it support displaying video-send-only statistics.and migrate the code for branch of m91.

# Call is terminated as websocket connection lost
Call is terminated as websocket connection lost in Loopback mode.However,websocket is not really used in loopback mode.
~~~
05-07 14:57:58.120 24294 24389 D de.tavendo.autobahn.WebSocketReader: run() : ConnectionLost
05-07 14:57:58.120 24294 24389 D de.tavendo.autobahn.WebSocketReader: WebSocket reader ended.
05-07 14:57:58.121 24294 24360 D de.tavendo.autobahn.WebSocketConnection: fail connection [code = CONNECTION_LOST, reason = WebSockets connection lost
05-07 14:57:58.121 24294 24360 D de.tavendo.autobahn.WebSocketReader: quit
05-07 14:57:58.122 24294 24390 D de.tavendo.autobahn.WebSocketWriter: WebSocket writer ended.
05-07 14:57:58.126 24294 24360 D WSChannelRTCClient: WebSocket connection closed. Code: CONNECTION_LOST. Reason: WebSockets connection lost. State: REGISTERED
05-07 14:57:58.126 24294 24360 D de.tavendo.autobahn.WebSocketConnection: worker threads stopped
05-07 14:57:58.126 24294 24294 D CallRTCClient: Remote end hung up; dropping PeerConnection
05-07 14:57:58.127 24294 24388 D de.tavendo.autobahn.WebSocketConnection: SocketThread exited.
05-07 14:57:58.134 24294 24360 D WSRTCClient: Disconnect. Room state: CONNECTED
05-07 14:57:58.134 24294 24360 D WSRTCClient: Closing room.
05-07 14:57:58.134 24294 24360 D WSRTCClient: C->GAE: https://www.rtc-gdemo.com/leave/71776268/84507087
05-07 14:57:58.134 24294 24360 D WSChannelRTCClient: Disconnect WebSocket. State: CLOSED
05-07 14:57:58.134 24294 24360 D WSChannelRTCClient: Disconnecting WebSocket done.
05-07 14:57:58.135 24294 24294 I EglRenderer: pip_video_viewReleasing.
05-07 14:57:58.136 24294 24358 I GlShader: Deleting shader.
05-07 14:57:58.136 24294 24358 I EglRenderer: pip_video_vieweglBase detach and release.
05-07 14:57:58.140 24294 24294 I EglRenderer: pip_video_viewReleasing done.
05-07 14:57:58.140 24294 24294 I EglRenderer: fullscreen_video_viewReleasing.
05-07 14:57:58.140 24294 24359 I GlShader: Deleting shader.
05-07 14:57:58.140 24294 24359 I EglRenderer: fullscreen_video_vieweglBase detach and release.
05-07 14:57:58.141  1025  1025 I chatty  : uid=1000(system) /system/bin/surfaceflinger expire 898 lines
05-07 14:57:58.143 24294 24358 I EglRenderer: pip_video_viewQuitting render thread.
05-07 14:57:58.145 24294 24359 I EglRenderer: fullscreen_video_viewQuitting render thread.
05-07 14:57:58.145 24294 24294 I EglRenderer: fullscreen_video_viewReleasing done.
05-07 14:57:58.145 24294 24294 D AppRTCAudioManager: stop
05-07 14:57:58.146 24294 24294 D AppRTCBluetoothManager: stop: BT state=HEADSET_UNAVAILABLE
05-07 14:57:58.147 24294 24294 I AudioManager: In isBluetoothScoOn(), calling application: org.appspot.apprtc
05-07 14:57:58.147  1650  4859 I chatty  : uid=1000(system) Binder:1650_1B expire 10 lines
05-07 14:57:58.147 24294 24294 D AppRTCBluetoothManager: stopScoAudio: BT state=HEADSET_UNAVAILABLE, SCO is on: false
05-07 14:57:58.148 24294 24294 D AppRTCBluetoothManager: cancelTimer
05-07 14:57:58.148 24294 24294 D AppRTCBluetoothManager: stop done: BT state=UNINITIALIZED
05-07 14:57:58.148 24294 24294 I AudioManager: In isSpeakerphoneOn(), calling application: org.appspot.apprtc
05-07 14:57:58.148 24294 24362 D PCRTCClient: Closing peer connection.

~~~

Use https in loopback mode instead.
~~~
05-07 15:03:03.010 24294 24646 D WSRTCClient: C->GAE: https://www.rtc-gdemo.com/message/3750863/99597691. Message: {"type":"candidate","label":0,"id":"0","candidate":"candidate:3883989995 1 udp 2122260223 30.19.30.0 37129 typ host generation 0 ufrag uRFj network-id 3 network-cost 10"}
05-07 15:03:03.010 24294 24646 D WSRTCClient: C->GAE: https://www.rtc-gdemo.com/message/3750863/99597691. Message: {"type":"candidate","label":0,"id":"0","candidate":"candidate:559267639 1 udp 2122202367 ::1 48588 typ host generation 0 ufrag uRFj network-id 2"}
~~~

# Run AV1 video codec test
![run_ut_failed_with_device_rooted](/image/run_ut_failed_with_device_rooted.jpg)

* Running unittest requires a device built with userdebug.Unfortunately,we don't have one. 
* TODO(Klaus):built one later,using Pixel device.

# Comparision between m91 and main,use AppRTCMobile
* There is not too much difference between resolution of 1280x720 and 720x1280
* Performance has difference between scenario of non-quick motion and quick motion.

**NOTE:** All tests have a limitation on `max_bitrate` of 875Kbps.

Test source file:ConferenceMotion_1280_720_50.y4m,this file is a resource file of unit tests.

|m91-not-optimized |m91-optimized|main-not-optimized|main-optimized|
|:---:|:---:|:---:|:----:|
|38412/903=42.5 | 1776/903=35.2 | 27740/727=38.2 | 25452/885=28.8 |

Test source file:ConferenceMotion_720_1280_50.y4m

| m91-not-optimized  | m91-optimized | main-not-optimized | main-optimized | 
| :---: | :---: | :---: | :----: | 
| 37552/889=42.2 | 31462/887=35.5 | 29188/777=37.7 | 26502/871=30.4 | 

Test source file:test_720_1280.y4m,this file is provided ty test engineer @吴万斌
* There is a running frame number(quickly changed) showed in the video file,so I think it  may belong to a scenario of quick motion.

| m91-not-optimized  | m91-optimized | main-not-optimized | main-optimized | 
| :---: | :---: | :---: | :----: | 
| 44394/902=49.2 | 42091/886=47.5 | 30353/751=40.4 | 28027/889=31.5 | 

# Issues sent to Google
[Issue 13951: Encoding speed(AV1) get to be much slower on Android platform when upgrading libaom from v2.0.2 to v3.3.0][Issue_13591]

![performance_test_result_from_google](/image/performance_test_result_from_google.jpg)

# References
[Issue_13591]: https://bugs.chromium.org/p/webrtc/issues/detail?id=13951&q=reporter%3Aaspling.zhang%40gmail.com&can=1

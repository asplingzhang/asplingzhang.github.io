---
layout: default
title: "Handle RTCP FIR PLI to generate key frame"
date: 2022-07-29 14:36:02 +0800
categories: [webrtc,rtcp]
---

# Abstract
This document describes that how to handle RTCP FIR PLI to generate key frame at send side.

# Diagrams
![Handle_RTCP_PLI_FIR](/image/Handle_RTCP_PLI_FIR.svg)

# Use field trial to control the frequency of key-frame generating
Too much frequent key-frame generating is not a best pratice for bitrate controlling at send side.

So we can control the interval of key-frame generating.And WebRTC has provided a field trial named `WebRTC-KeyframeInterval` for doing that.
- Use `min_keyframe_send_interval_ms` to control the interval for key-frame generating.
```C++
#include "rtc_base/experiments/keyframe_interval_settings.h"
namespace {
constexpr char kFieldTrialName[] = "WebRTC-KeyframeInterval";
}  // namespace
KeyframeIntervalSettings::KeyframeIntervalSettings(
    const WebRtcKeyValueConfig* const key_value_config)
    : min_keyframe_send_interval_ms_("min_keyframe_send_interval_ms") {
  ParseFieldTrial({&min_keyframe_send_interval_ms_},
                  key_value_config->Lookup(kFieldTrialName));
}
```

# Copyright notice
All Rights Reserved.Any rep/irint/reproduce/redistribution of this article MUST indicate the source. 

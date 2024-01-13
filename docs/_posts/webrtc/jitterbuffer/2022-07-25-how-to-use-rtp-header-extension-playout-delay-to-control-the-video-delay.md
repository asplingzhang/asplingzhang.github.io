---
layout: default
title: "How to use RTP header extension playout-delay to control the video delay"
date: 2022-07-25 16:41:56 +0800
categories: webrtc
---

# Abstract
This documents describes that how to use RTP header extension playout-delay to control the video delay of receiver side.

# Playout-delay RTP header extension
Introducion please see [playout-delay](https://webrtc.googlesource.com/src/+/refs/heads/master/docs/native-code/rtp-hdrext/playout-delay/).
```shell
RTP header extension format
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|  ID   | len=2 |       MIN delay       |       MAX delay       |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
12 bits for Minimum and Maximum delay. This represents a range of 0 - 40950 milliseconds for minimum and maximum (with a granularity of 10 ms). A granularity of 10 ms is sufficient since we expect the following typical use cases:

0 ms: Certain gaming scenarios (likely without audio) where we will want to play the frame as soon as possible. Also, for remote desktop without audio where rendering a frame asap makes sense
100/150/200 ms: These could be the max target latency for interactive streaming use cases depending on the actual application (gaming, remoting with audio, interactive scenarios)
400 ms: Application that want to ensure a network glitch has very little chance of causing a freeze can start with a minimum delay target that is high enough to deal with network issues. Video streaming is one example.
```


# Negotiating Playout-delay RTP header extension through Offer/Answer

We need enable Playout-delay by negotiating Playout-delay RTP header extension support through Offer and Answer.
In the Offer:
```shell
offer\
m=video 9 UDP/TLS/RTP/SAVPF 96 97 35 36 98 99 100 37\
a=setup:actpass\
a=mid:1\
a=extmap:12 http://www.webrtc.org/experiments/rtp-hdrext/playout-delay\
```
In the Answer:
```shell
answer\
a=extmap:12 http://www.webrtc.org/experiments/rtp-hdrext/playout-delay\
```

How to check that if video engine supports Playout-delay?
```C++
std::vector<webrtc::RtpHeaderExtensionCapability>
WebRtcVideoEngine::GetRtpHeaderExtensions() const {
  std::vector<webrtc::RtpHeaderExtensionCapability> result;
  int id = 1;
  for (const auto& uri :
       {webrtc::RtpExtension::kTimestampOffsetUri,
        webrtc::RtpExtension::kAbsSendTimeUri,
        webrtc::RtpExtension::kVideoRotationUri,
        webrtc::RtpExtension::kTransportSequenceNumberUri,
        webrtc::RtpExtension::kPlayoutDelayUri,
        webrtc::RtpExtension::kVideoContentTypeUri,
        webrtc::RtpExtension::kVideoTimingUri,
        webrtc::RtpExtension::kColorSpaceUri, webrtc::RtpExtension::kMidUri,
        webrtc::RtpExtension::kRidUri, webrtc::RtpExtension::kRepairedRidUri,
        webrtc::RtpExtension::kRsFecUri}) {
    result.emplace_back(uri, id++, webrtc::RtpTransceiverDirection::kSendRecv);
  }
  result.emplace_back(webrtc::RtpExtension::kGenericFrameDescriptorUri00, id++,
                      IsEnabled(trials_, "WebRTC-GenericDescriptorAdvertised")
                          ? webrtc::RtpTransceiverDirection::kSendRecv
                          : webrtc::RtpTransceiverDirection::kStopped);
  result.emplace_back(
      webrtc::RtpExtension::kDependencyDescriptorUri, id++,
      IsEnabled(trials_, "WebRTC-DependencyDescriptorAdvertised")
          ? webrtc::RtpTransceiverDirection::kSendRecv
          : webrtc::RtpTransceiverDirection::kStopped);

  result.emplace_back(
      webrtc::RtpExtension::kVideoLayersAllocationUri, id++,
      IsEnabled(trials_, "WebRTC-VideoLayersAllocationAdvertised")
          ? webrtc::RtpTransceiverDirection::kSendRecv
          : webrtc::RtpTransceiverDirection::kStopped);

  result.emplace_back(
      webrtc::RtpExtension::kVideoFrameTrackingIdUri, id++,
      IsEnabled(trials_, "WebRTC-VideoFrameTrackingIdAdvertised")
          ? webrtc::RtpTransceiverDirection::kSendRecv
          : webrtc::RtpTransceiverDirection::kStopped);

  return result;
}
```

# Set min_ms and max_ms of Playout-delay
- initialize value of Playout-delay from field trial `WebRTC-ForcePlayoutDelay`.
```C++
RTPSenderVideo::RTPSenderVideo(const Config& config)
    : rtp_sender_(config.rtp_sender),
      current_playout_delay_{-1, -1},
      playout_delay_pending_(false),
      forced_playout_delay_(LoadVideoPlayoutDelayOverride(config.field_trials)){
}
absl::optional<VideoPlayoutDelay> LoadVideoPlayoutDelayOverride(
    const WebRtcKeyValueConfig* key_value_config) {
  FieldTrialOptional<int> playout_delay_min_ms("min_ms", absl::nullopt);
  FieldTrialOptional<int> playout_delay_max_ms("max_ms", absl::nullopt);
  ParseFieldTrial({&playout_delay_max_ms, &playout_delay_min_ms},
                  key_value_config->Lookup("WebRTC-ForcePlayoutDelay"));
  return playout_delay_max_ms && playout_delay_min_ms
             ? absl::make_optional<VideoPlayoutDelay>(*playout_delay_min_ms,
                                                      *playout_delay_max_ms)
             : absl::nullopt;
}
```
  - `current_playout_delay_` is initialized to default invalid value {-1,-1}
  - `forced_playout_delay_` is initialized from field trial.

# Adding Playout-delay RTP header extension
-  Update value of Playout-delay
```C++
void RTPSenderVideo::MaybeUpdateCurrentPlayoutDelay(
    const RTPVideoHeader& header) {
  VideoPlayoutDelay requested_delay =
      forced_playout_delay_.value_or(header.playout_delay);
}
```
- Add Playout-delay to RTP header extensions.
```C++
void RTPSenderVideo::AddRtpHeaderExtensions(
    const RTPVideoHeader& video_header,
    const absl::optional<AbsoluteCaptureTime>& absolute_capture_time,
    bool first_packet,
    bool last_packet,
    RtpPacketToSend* packet) const {
    // If transmitted, add to all packets; ack logic depends on this.
  if (playout_delay_pending_) {
    packet->SetExtension<PlayoutDelayLimits>(current_playout_delay_);
  }
}
```

# Stop sending Playout-delay when acknowledge is received
It's the former strategy on Playout-delay.See details in previous WebRTC with `modules/rtp_rtcp/source/playout_delay_oracle.cc` implemented.

For latest WebRTC,the strategy changed
- Use `playout_delay_pending_` to indicate whether we need keep sending Playout-delay or not.
- Send Playout-delay for all Key frames
  ```C++
  if (video_header.frame_type == VideoFrameType::kVideoFrameKey) {
    if (!IsNoopDelay(current_playout_delay_)) {
      // Force playout delay on key-frames, if set.
      playout_delay_pending_ = true;
    }
    if (allocation_) {
      // Send the bitrate allocation on every key frame.
      send_allocation_ = SendVideoLayersAllocation::kSendWithResolution;
    }
  }
  ```
- Reset to `playout_delay_pending_` false when these kind frame was sent.
  ```C++
  if (video_header.frame_type == VideoFrameType::kVideoFrameKey ||
      PacketWillLikelyBeRequestedForRestransmitionIfLost(video_header)) {
    // This frame will likely be delivered, no need to populate playout
    // delay extensions until it changes again.
    playout_delay_pending_ = false;
    send_allocation_ = SendVideoLayersAllocation::kDontSend;
  }
  ```

Why the strategy changed like this
- it's more simple as ack mechanism is remove.
- it's more friend to SFU,as SFU don't need cache the Playout-delay anymore.in the former case,if we don't want the sender keep sending Packets with Playout-delay ,we neeed cache the Playout-delay sent by sender,then send the cached value to any new subscribers.in the latest version,we send Playout-delay every Key frame,and in case of new subscriber,Key frame is the first video frame he received.

# How to use Playout-delay to control video delay at receiver side
- Apply Playout-delay at receiver side by setting `frame_minimum_playout_delay_ms_` and `frame_maximum_playout_delay_ms_`
```C++
void VideoReceiveStream2::OnCompleteFrame(std::unique_ptr<EncodedFrame> frame) {
  RTC_DCHECK_RUN_ON(&worker_sequence_checker_);

  const VideoPlayoutDelay& playout_delay = frame->EncodedImage().playout_delay_;
  if (playout_delay.min_ms >= 0) {
    frame_minimum_playout_delay_ms_ = playout_delay.min_ms;
    UpdatePlayoutDelays();
  }

  if (playout_delay.max_ms >= 0) {
    frame_maximum_playout_delay_ms_ = playout_delay.max_ms;
    UpdatePlayoutDelays();
  }
}
```
- `frame_minimum_playout_delay_ms_` and `frame_maximum_playout_delay_ms_` can affect the `targetDelayMs` of jitter buffer,by which we can control the video delay.

# Shortages of Playout-delay
Playout-delay can change the delay of video quickly,however,it do have its own shortages.
1. it's not flexiable as the value of Playout-delay is fixed.it cann't adapt the network conditions of receiver smartly.
2. it may be conflict with AV-synchronization.for example,audio delay is high,so we need increase the extra delay of video to the audio video sync.However,the increasing extra delay of video can be prevented by Playout-delay.

# Copyright notice
All Rights Reserved.Any reprint/reproduce/redistribution of this article MUST indicate the source. 

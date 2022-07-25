---
layout: default
title: "Current delay and jitter buffer delay in jitter buffer of video"
date: 2022-07-22 11:35:11 +0800
categories: [webrtc,jitterbuffer]
---

# Abstract
This documents describes current  delay and jitter buffer delay in jitter buffer of video.

# Official definition at W3C

See [webrtc-stats](https://www.w3.org/TR/webrtc-stats/#receivedrtpstats-dict*)

```shell
jitterBufferDelay of type double
The purpose of the jitter buffer is to recombine RTP packets into frames (in the case of video) and have smooth playout. The model described here assumes that the samples or frames are still compressed and have not yet been decoded. It is the sum of the time, in seconds, each audio sample or a video frame takes from the time the first packet is received by the jitter buffer (ingest timestamp) to the time it exits the jitter buffer (emit timestamp). In the case of audio, several samples belong to the same RTP packet, hence they will have the same ingest timestamp but different jitter buffer emit timestamps. In the case of video, the frame maybe is received over several RTP packets, hence the ingest timestamp is the earliest packet of the frame that entered the jitter buffer and the emit timestamp is when the whole frame exits the jitter buffer. This metric increases upon samples or frames exiting, having completed their time in the buffer (and incrementing jitterBufferEmittedCount). The average jitter buffer delay can be calculated by dividing the jitterBufferDelay with the jitterBufferEmittedCount.

jitterBufferTargetDelay of type double
This value is increased by the target jitter buffer delay every time a sample is emitted by the jitter buffer. The added target is the target delay, in seconds, at the time that the sample was emitted from the jitter buffer. To get the average target delay, divide by jitterBufferEmittedCount.

jitterBufferEmittedCount of type unsigned long long
The total number of audio samples or video frames that have come out of the jitter buffer (increasing jitterBufferDelay).

jitterBufferMinimumDelay of type double
There are various reasons why the jitter buffer delay might be increased to a higher value, such as to achieve AV synchronization or because a playoutDelay was set on a RTCRtpReceiver. When using one of these mechanisms, it can be useful to keep track of the minimal jitter buffer delay that could have been achieved, so WebRTC clients can track the amount of additional delay that is being added.

This metric works the same way as jitterBufferTargetDelay, except that it is not affected by external mechanisms that increase the jitter buffer target delay, such as playoutDelay (see link above), AV sync, or any other mechanisms. This metric is purely based on the network characteristics such as jitter and packet loss, and can be seen as the minimum obtainable jitter buffer delay if no external factors would affect it. The metric is updated every time jitterBufferEmittedCount is updated.
```
- googCurrentDelayMs and googJitterBufferMs is not  defined in standard webrtc-stats.googCurrentDelayMs is the current estimated delay,googJitterBufferMs is the current length of the jitter buffer.
- jitterBufferDelay/jitterBufferTargetDelay are standard stats items.
- We can calculte average jitterBufferDelay and jitterBufferTargetDeay.

# Sequence diagram
![JitterBuffer_Delays](/image/JitterBuffer_Delays.svg)

# googCurrentDelayMs
`googCurrentDelayMs` describes the current delay by adding the actual delay of the latest video frame(go out from jitter buffer) accumulatedly.`googCurrentDelayMs` is designed to be convergenced at `googTargetDelayMs`.
- if `actual delay < 0`,`googCurrentDelayMs` is not updated.
- `googCurrentDelayMs < googTargetDelayMs`

`googCurrentDelayMs = total_delay_accumulated,googCurrentDelayMs < googTargetDelayMs`.
- When `googCurrentDelayMs` is high,always means the delay of video is high.at the same time ,`googTargetDelayMs` is high too,However,`googJitterBufferMs` may not be high.

# googJitterBufferMs and googPreferredJitterBufferMs
`googJitterBufferMs` is the current jitter delay.it's calculated by video jitter estimator.Corresponding parameter's name is `jitter_delay_ms_`.
There is no `googPreferredJitterBufferMs` in video jitter buffer.

# jitterBufferDelay and jitterBufferTargetDelay 
See definition above.

# How to get current estimated delay googCurrentDelayMs and current length of jitter buffer  googJitterBufferMs from statistics
Same as chapter below.
# How to get jitterBufferDelay and jitterBufferTargetDelay from statistics
-  Key of these stats
```C++
#include "api/stats_types.h"
const char* StatsReport::Value::display_name() const {
  switch (name) {
case kStatsValueNameCurrentDelayMs:
      return "googCurrentDelayMs";
    case kStatsValueNameTargetDelayMs:
      return "googTargetDelayMs";
    case kStatsValueNameJitterBufferMs:
      return "googJitterBufferMs";
    case kStatsValueNameMinPlayoutDelayMs:
      return "googMinPlayoutDelayMs";
}
```

- Get stats from stats_collector
```C++
void ExtractStats(const xcricket::VideoReceiverInfo& info,
                  StatsReport* report,
                  bool use_standard_bytes_stats) {
  ExtractCommonReceiveProperties(info, report);
  const IntForAdd ints[] = {
      {StatsReport::kStatsValueNameCurrentDelayMs, info.current_delay_ms},
      {StatsReport::kStatsValueNameDecodeMs, info.decode_ms},
      {StatsReport::kStatsValueNameFirsSent, info.firs_sent},
      {StatsReport::kStatsValueNameFrameHeightReceived, info.frame_height},
      {StatsReport::kStatsValueNameFrameRateDecoded, info.framerate_decoded},
      {StatsReport::kStatsValueNameFrameRateOutput, info.framerate_output},
      {StatsReport::kStatsValueNameFrameRateReceived, info.framerate_rcvd},
      {StatsReport::kStatsValueNameFrameWidthReceived, info.frame_width},
      {StatsReport::kStatsValueNameJitterBufferMs, info.jitter_buffer_ms},
      {StatsReport::kStatsValueNameMaxDecodeMs, info.max_decode_ms},
      {StatsReport::kStatsValueNameMinPlayoutDelayMs,
       info.min_playout_delay_ms},
      {StatsReport::kStatsValueNameNacksSent, info.nacks_sent},
      {StatsReport::kStatsValueNamePacketsLost, info.packets_lost},
      {StatsReport::kStatsValueNamePacketsReceived, info.packets_rcvd},
      {StatsReport::kStatsValueNamePlisSent, info.plis_sent},
      {StatsReport::kStatsValueNameRenderDelayMs, info.render_delay_ms},
      {StatsReport::kStatsValueNameTargetDelayMs, info.target_delay_ms},
      {StatsReport::kStatsValueNameFramesDecoded, info.frames_decoded},
  };
}
```

- Get `current_delay_ms` as current accumulated  delay from jitter buffer.
- Get `jitter_buffer_ms` as current jitter delay of jitter buffer.
```C++
VideoReceiveStream::Stats VideoReceiveStream2::GetStats() const {
  RTC_DCHECK_RUN_ON(&worker_sequence_checker_);
  VideoReceiveStream2::Stats stats = stats_proxy_.GetStats();
  stats.total_bitrate_bps = 0;
  StreamStatistician* statistician =
      rtp_receive_statistics_->GetStatistician(stats.ssrc);
  if (statistician) {
    stats.rtp_stats = statistician->GetStats();
    stats.total_bitrate_bps = statistician->BitrateReceived();
  }
  if (config_.rtp.rtx_ssrc) {
    StreamStatistician* rtx_statistician =
        rtp_receive_statistics_->GetStatistician(config_.rtp.rtx_ssrc);
    if (rtx_statistician)
      stats.total_bitrate_bps += rtx_statistician->BitrateReceived();
  }
  return stats;
}
VideoReceiveStream::Stats ReceiveStatisticsProxy::GetStats() const {
  RTC_DCHECK_RUN_ON(&main_thread_);

  // Like VideoReceiveStream::GetStats, called on the worker thread from
  // StatsCollector::ExtractMediaInfo via worker_thread()->Invoke().
  // WebRtcVideoChannel::GetStats(), GetVideoReceiverInfo.

  // Get current frame rates here, as only updating them on new frames prevents
  // us from ever correctly displaying frame rate of 0.
  int64_t now_ms = clock_->TimeInMilliseconds();
  UpdateFramerate(now_ms);

  stats_.render_frame_rate = renders_fps_estimator_.Rate(now_ms).value_or(0);
  stats_.decode_frame_rate = decode_fps_estimator_.Rate(now_ms).value_or(0);

  if (last_decoded_frame_time_ms_) {
    // Avoid using a newer timestamp than might be pending for decoded frames.
    // If we do use now_ms, we might roll the max window to a value that is
    // higher than that of a decoded frame timestamp that we haven't yet
    // captured the data for (i.e. pending call to OnDecodedFrame).
    stats_.interframe_delay_max_ms =
        interframe_delay_max_moving_.Max(*last_decoded_frame_time_ms_)
            .value_or(-1);
  } else {
    // We're paused. Avoid changing the state of |interframe_delay_max_moving_|.
    stats_.interframe_delay_max_ms = -1;
  }

  stats_.freeze_count = video_quality_observer_->NumFreezes();
  stats_.pause_count = video_quality_observer_->NumPauses();
  stats_.total_freezes_duration_ms =
      video_quality_observer_->TotalFreezesDurationMs();
  stats_.total_pauses_duration_ms =
      video_quality_observer_->TotalPausesDurationMs();
  stats_.total_frames_duration_ms =
      video_quality_observer_->TotalFramesDurationMs();
  stats_.sum_squared_frame_durations =
      video_quality_observer_->SumSquaredFrameDurationsSec();
  stats_.content_type = last_content_type_;
  stats_.timing_frame_info = timing_frame_info_counter_.Max(now_ms);
  stats_.jitter_buffer_delay_seconds =
      static_cast<double>(current_delay_counter_.Sum(1).value_or(0)) /
      rtc::kNumMillisecsPerSec;
  stats_.jitter_buffer_emitted_count = current_delay_counter_.NumSamples();
  stats_.estimated_playout_ntp_timestamp_ms =
      GetCurrentEstimatedPlayoutNtpTimestampMs(now_ms);
  return stats_;
}
void ReceiveStatisticsProxy::OnFrameBufferTimingsUpdated(
    int max_decode_ms,
    int current_delay_ms,
    int target_delay_ms,
    int jitter_buffer_ms,
    int min_playout_delay_ms,
    int render_delay_ms) {
  RTC_DCHECK_RUN_ON(&decode_queue_);
  worker_thread_->PostTask(ToQueuedTask(
      task_safety_,
      [max_decode_ms, current_delay_ms, target_delay_ms, jitter_buffer_ms,
       min_playout_delay_ms, render_delay_ms, this]() {
        RTC_DCHECK_RUN_ON(&main_thread_);
        stats_.max_decode_ms = max_decode_ms;
        stats_.current_delay_ms = current_delay_ms;
        stats_.target_delay_ms = target_delay_ms;
        stats_.jitter_buffer_ms = jitter_buffer_ms;
        stats_.min_playout_delay_ms = min_playout_delay_ms;
        stats_.render_delay_ms = render_delay_ms;
        jitter_buffer_delay_counter_.Add(jitter_buffer_ms);
        target_delay_counter_.Add(target_delay_ms);
        current_delay_counter_.Add(current_delay_ms);
        // Network delay (rtt/2) + target_delay_ms (jitter delay + decode time +
        // render delay).
        delay_counter_.Add(target_delay_ms + avg_rtt_ms_ / 2);
      }));
}
bool VCMTiming::GetTimings(int* max_decode_ms,
                           int* current_delay_ms,
                           int* target_delay_ms,
                           int* jitter_buffer_ms,
                           int* min_playout_delay_ms,
                           int* render_delay_ms) const {
  MutexLock lock(&mutex_);
  *max_decode_ms = RequiredDecodeTimeMs();
  *current_delay_ms = current_delay_ms_;
  *target_delay_ms = TargetDelayInternal();
  *jitter_buffer_ms = jitter_delay_ms_;
  *min_playout_delay_ms = min_playout_delay_ms_;
  *render_delay_ms = render_delay_ms_;
  return (num_decoded_frames_ > 0);
}
```

# Copyright notice
All Rights Reserved.Any reprint/reproduce/redistribution of this article MUST indicate the source. 

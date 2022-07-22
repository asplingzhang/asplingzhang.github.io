---
layout: default
title: "Google-private stats googCurrentDelayMs/googJitterBufferMs/googPreferredJitterBufferMs and standard stats item jitterBufferDelay/jitterBufferTargetDelay in NetEQ"
date: 2022-07-22 11:34:50 +0800
categories: [webrtc,neteq]
---

# Abstract
This documents describes the definitions of current estimated delay named `googCurrentDelayMs` and jitter buffer delay named `googJitterBufferMs` in NetEQ.
Also,include the standard stats items,e.g,jitterBufferDelay/jitterBufferTargetDelay 

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
![NetEQ_Delays](/image/NetEQ_Delays.svg)

# googCurrentDelayMs

`googCurrentDelayMs = (filtered_buffer_level + samples_in_sync_buffer)/fs_hz + playout_delay_ms`.
- `filtered_buffer_level` is decided by `delay manager`.
- Current estimated delay is the sum of target delay and length of sync buffer,Usually,`playout_delay_ms` is solid,the mostly influence factor is `target delay`.
- When `googCurrentDelayMs` is high,always means the delay of audio is high.

# googJitterBufferMs and googPreferredJitterBufferMs
`googJitterBufferMs` is the current length of jitter buffer,including length of PacketBuffer and SyncBuffer.
`googPreferredJitterBufferMs` is the current estimated delay from delay manager.

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
#include "pc/stats_collector.h"
void ExtractStats(const xcricket::VoiceReceiverInfo& info,
                  StatsReport* report,
                  bool use_standard_bytes_stats) {
                  const IntForAdd ints[] = {
      {StatsReport::kStatsValueNameCurrentDelayMs, info.delay_estimate_ms},
      {StatsReport::kStatsValueNameJitterBufferMs, info.jitter_buffer_ms},
      {StatsReport::kStatsValueNameJitterReceived, info.jitter_ms},
  };
  ......
  report->AddString(StatsReport::kStatsValueNameMediaType, "audio");
}
```

- Get `delay_estimate_ms` as current estimated delay from NetEQ.

```C++
#include "audio/audio_receive_stream.h"
xwebrtc::AudioReceiveStream::Stats AudioReceiveStream::GetStats(
    bool get_and_clear_legacy_stats) const {
  //Current Delay
  stats.delay_estimate_ms = channel_receive_->GetDelayEstimate();

    // Get jitter buffer and total delay (alg + jitter + playout) stats.
  auto ns = channel_receive_->GetNetworkStatistics(get_and_clear_legacy_stats);
  //JitterBuffer Delay
  stats.jitter_buffer_ms = ns.currentBufferSize;
  stats.jitter_buffer_preferred_ms = ns.preferredBufferSize;
}
uint32_t ChannelReceive::GetDelayEstimate() const {
  RTC_DCHECK_RUN_ON(&worker_thread_checker_);

  uint32_t playout_delay;
  {
    MutexLock lock(&video_sync_lock_);
    playout_delay = playout_delay_ms_;
  }
  // Return the current jitter buffer delay + playout delay.
  return acm_receiver_.FilteredCurrentDelayMs() + playout_delay;
}
```

- Get `currentBufferSize` as jitter buffer length
- Get `jitterBufferDelayMs/jitterBufferTargetDelayMs` as the corresponding standard stats.

```C++
void AcmReceiver::GetNetworkStatistics(
    NetworkStatistics* acm_stat,
    bool get_and_clear_legacy_stats /* = true */) const {
  NetEqNetworkStatistics neteq_stat;
  if (get_and_clear_legacy_stats) {
    // NetEq function always returns zero, so we don't check the return value.
    neteq_->NetworkStatistics(&neteq_stat);

    acm_stat->currentExpandRate = neteq_stat.expand_rate;
    acm_stat->currentSpeechExpandRate = neteq_stat.speech_expand_rate;
    acm_stat->currentPreemptiveRate = neteq_stat.preemptive_rate;
    acm_stat->currentAccelerateRate = neteq_stat.accelerate_rate;
    acm_stat->currentSecondaryDecodedRate = neteq_stat.secondary_decoded_rate;
    acm_stat->currentSecondaryDiscardedRate =
        neteq_stat.secondary_discarded_rate;
    acm_stat->meanWaitingTimeMs = neteq_stat.mean_waiting_time_ms;
    acm_stat->maxWaitingTimeMs = neteq_stat.max_waiting_time_ms;
  } else {
    neteq_stat = neteq_->CurrentNetworkStatistics();
    acm_stat->currentExpandRate = 0;
    acm_stat->currentSpeechExpandRate = 0;
    acm_stat->currentPreemptiveRate = 0;
    acm_stat->currentAccelerateRate = 0;
    acm_stat->currentSecondaryDecodedRate = 0;
    acm_stat->currentSecondaryDiscardedRate = 0;
    acm_stat->meanWaitingTimeMs = -1;
    acm_stat->maxWaitingTimeMs = 1;
  }
  acm_stat->currentBufferSize = neteq_stat.current_buffer_size_ms;
  acm_stat->preferredBufferSize = neteq_stat.preferred_buffer_size_ms;
  acm_stat->jitterPeaksFound = neteq_stat.jitter_peaks_found ? true : false;

  NetEqLifetimeStatistics neteq_lifetime_stat = neteq_->GetLifetimeStatistics();
  acm_stat->totalSamplesReceived = neteq_lifetime_stat.total_samples_received;
  acm_stat->concealedSamples = neteq_lifetime_stat.concealed_samples;
  acm_stat->silentConcealedSamples =
      neteq_lifetime_stat.silent_concealed_samples;
  acm_stat->concealmentEvents = neteq_lifetime_stat.concealment_events;
  acm_stat->jitterBufferDelayMs = neteq_lifetime_stat.jitter_buffer_delay_ms;
  acm_stat->jitterBufferTargetDelayMs =
      neteq_lifetime_stat.jitter_buffer_target_delay_ms;
  acm_stat->jitterBufferEmittedCount =
      neteq_lifetime_stat.jitter_buffer_emitted_count;
  acm_stat->delayedPacketOutageSamples =
      neteq_lifetime_stat.delayed_packet_outage_samples;
  acm_stat->relativePacketArrivalDelayMs =
      neteq_lifetime_stat.relative_packet_arrival_delay_ms;
  acm_stat->interruptionCount = neteq_lifetime_stat.interruption_count;
  acm_stat->totalInterruptionDurationMs =
      neteq_lifetime_stat.total_interruption_duration_ms;
  acm_stat->insertedSamplesForDeceleration =
      neteq_lifetime_stat.inserted_samples_for_deceleration;
  acm_stat->removedSamplesForAcceleration =
      neteq_lifetime_stat.removed_samples_for_acceleration;
  acm_stat->fecPacketsReceived = neteq_lifetime_stat.fec_packets_received;
  acm_stat->fecPacketsDiscarded = neteq_lifetime_stat.fec_packets_discarded;

  NetEqOperationsAndState neteq_operations_and_state =
      neteq_->GetOperationsAndState();
  acm_stat->packetBufferFlushes =
      neteq_operations_and_state.packet_buffer_flushes;
}
NetEqNetworkStatistics NetEqImpl::CurrentNetworkStatisticsInternal() const {
  assert(decoder_database_.get());
  NetEqNetworkStatistics stats;
  const size_t total_samples_in_buffers =
      packet_buffer_->NumSamplesInBuffer(decoder_frame_length_) +
      sync_buffer_->FutureLength();

  assert(controller_.get());
  stats.preferred_buffer_size_ms = controller_->TargetLevelMs();
  stats.jitter_peaks_found = controller_->PeakFound();
  RTC_DCHECK_GT(fs_hz_, 0);
  stats.current_buffer_size_ms =
      static_cast<uint16_t>(total_samples_in_buffers * 1000 / fs_hz_);

  // Compensate for output delay chain.
  stats.current_buffer_size_ms += output_delay_chain_ms_;
  stats.preferred_buffer_size_ms += output_delay_chain_ms_;
  return stats;
}
```

# Copyright notice
All Rights Reserved.Any reprint/reproduce/redistribution of this article MUST indicate the source. 

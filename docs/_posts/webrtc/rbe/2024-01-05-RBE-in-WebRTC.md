---
layout: default
title:  "RBE(Remote Bitrate Estimate) in WebRTC"
date:   2024-01-05 15:31:33 +0800
categories: [webrtc]
---

# Explanation of the OveruseEstimator code in WebRTC

## Basic description

This code defines an `OveruseEstimator` class in WebRTC that estimates the inter-arrival time delta offset and noise variance to improve bitrate adaptation. Here's a breakdown of the key functionalities:

**1. Purpose:**

The `OveruseEstimator` aims to accurately estimate the true inter-arrival time of media packets and filter out noise/jitter introduced by the network. This information helps the Remote Bitrate Estimator (RBE) in WebRTC adjust the sending bitrate based on the available bandwidth and network conditions.

**2. Key Concepts:**

* **Inter-arrival time delta:** The difference between the arrival times of consecutive packets.
* **Offset:** The estimated deviation between the actual and expected inter-arrival time delta.
* **Noise variance:** The estimated variance of the observed noise/jitter in the network.
* **Kalman filter:** A statistical method used to estimate the state of a system based on noisy observations.

**3. Code Breakdown:**

* **Public methods:**
    * **Update:** Takes new samples (inter-arrival time delta, size delta, bandwidth hypothesis, timestamp) and updates the internal state of the estimator.
    * **var_noise:** Returns the estimated noise/jitter variance.
    * **offset:** Returns the estimated inter-arrival time delta offset.
    * **num_of_deltas:** Returns the number of samples used for the current estimation.
* **Private methods:**
    * **UpdateMinFramePeriod:** Estimates the minimum frame period based on recent observations.
    * **UpdateNoiseEstimate:** Updates the noise variance based on the latest residual (observed delta minus estimated delta).
* **State variables:**
    * `num_of_deltas_`: Number of deltas used for the current estimation.
    * `slope_`: Estimated slope of the inter-arrival time delta.
    * `offset_`: Estimated inter-arrival time delta offset.
    * `prev_offset_`: Previously estimated offset.
    * `E_`: Covariance matrix used in the Kalman filter.
    * `process_noise_`: Process noise matrix used in the Kalman filter.
    * `avg_noise_`: Average noise observed over time.
    * `var_noise_`: Estimated variance of the noise/jitter.
    * `ts_delta_hist_`: History of recent timestamp deltas.

**4. Estimation Algorithm:**

* The `Update` function takes new samples and incorporates them into the Kalman filter.
* The filter estimates the slope and offset of the inter-arrival time delta, accounting for noise and previous observations.
* The `UpdateMinFramePeriod` function helps estimate the minimum time between frames, which can be useful for filtering out outliers.
* The `UpdateNoiseEstimate` function updates the noise variance based on the difference between the observed and estimated inter-arrival times.
* The estimator adapts its parameters based on the current bandwidth hypothesis (overusing, underusing, or normal) to improve accuracy.

**5. Output:**

* The `var_noise` function provides an estimate of the network noise variance.
* The `offset` function provides an estimate of the inter-arrival time delta offset.
* These values are used by the RBE algorithm to adjust the sending bitrate and ensure smooth and efficient video streaming.

**6. Conclusion:**

Understanding the `OveruseEstimator` code sheds light on a crucial component of RBE in WebRTC. It demonstrates how the estimator utilizes the Kalman filter and adapts to network conditions to provide accurate information for bitrate control, ultimately contributing to a better video streaming experience.

## Kalman Filter Model in WebRTC's OveruseEstimator

The OveruseEstimator in WebRTC utilizes the Kalman filter to estimate the state of the inter-arrival time delta and noise variance in a network. Here's a detailed breakdown of the model:

**1. State:**

The state vector `x` in this model is defined as:

```
x = [offset, slope]^T
```

* **offset:** The estimated deviation between the actual and expected inter-arrival time delta.
* **slope:** The estimated slope of the inter-arrival time delta.

**2. Transition Matrix (F):**

The transition matrix `F` describes how the state evolves over time. In this case, it reflects the assumption that the offset and slope remain constant between updates:

```
F = [[1, 0],
      [0, 1]]
```

**3. Process Noise (Q):**

Process noise represents the uncertainty in the state transition model. It is a diagonal matrix with variances associated with the offset and slope:

```
Q = [[process_noise_[0], 0],
      [0, process_noise_[1]]]
```

* `process_noise_[0]`: Variance of the offset uncertainty.
* `process_noise_[1]`: Variance of the slope uncertainty.

**4. Measurement Matrix (H):**

The measurement matrix `H` relates the state to the observations. Here, the observation is the actual inter-arrival time delta (t_delta):

```
H = [fs_delta, 1]
```

* `fs_delta`: Size delta of the received data packet.

**5. Measurement Noise (R):**

Measurement noise represents the uncertainty in the observation due to network noise and jitter. It is a scalar representing the variance of the noise:

```
R = var_noise
```

* `var_noise`: Estimated variance of the noise/jitter in the network.

**6. Measurement (y):**

The measurement vector `y` is the actual inter-arrival time delta observed for the current data packet:

```
y = t_delta
```

**7. Update Equations:**

The Kalman filter uses the following equations to update its internal state based on new observations:

* **State prediction:**
  ```
  x_pred = F * x_prev
  ```
* **Prediction covariance:**
  ```
  P_pred = F * P_prev * F^T + Q
  ```
* **Kalman gain:**
  ```
  K = P_pred * H^T / (H * P_pred * H^T + R)
  ```
* **State update:**
  ```
  x_est = x_pred + K * (y - H * x_pred)
  ```
* **Updated covariance:**
  ```
  P_est = (I - K * H) * P_pred
  ```

**8. Adaptivity:**

The OveruseEstimator adapts the process noise and measurement noise variances based on the observed network conditions and current bandwidth hypothesis. This allows the filter to become more or less sensitive to fluctuations in the inter-arrival time delta depending on the network state.

**9. Conclusion:**

The Kalman filter model in the OveruseEstimator provides a robust and adaptable framework for estimating the inter-arrival time delta and noise variance in a network. This information is crucial for the RBE algorithm to adjust the sending bitrate and achieve optimal video streaming performance.

### Breakdown of the Kalman filter model in the OveruseEstimator

**Here's a breakdown of the Kalman filter model in the OveruseEstimator, including equations and explanations:**

**1. State Equations**

* State vector `x`:
  ```
  x = [offset, slope]^T
  ```
* Transition matrix `F`:
  ```
  F = [[1, 0],
       [0, 1]]
  ```
* Process noise `Q`:
  ```
  Q = [[process_noise_[0], 0],
       [0, process_noise_[1]]]
  ```

**2. Observation Equations**

* Measurement matrix `H`:
  ```
  H = [fs_delta, 1]
  ```
* Measurement `y`:
  ```
  y = t_delta
  ```
* Measurement noise `R`:
  ```
  R = var_noise
  ```

**3. Kalman Filter Theory**

The Kalman filter iteratively performs two steps:

**Prediction:**
1. Predicts the next state based on the current state and process model:
   ```
   x_pred = F * x_prev
   P_pred = F * P_prev * F^T + Q
   ```

**Update:**
2. Incorporates new observations to refine the predicted state:
   ```
   K = P_pred * H^T / (H * P_pred * H^T + R)
   x_est = x_pred + K * (y - H * x_pred)
   P_est = (I - K * H) * P_pred
   ```

**4. Key Concepts**

* State: Represents the system's underlying characteristics (offset and slope in this case).
* Process model: Describes how the state evolves over time (assumed constant here).
* Measurement model: Relates the state to observed measurements (inter-arrival time delta).
* Process noise: Uncertainty in the state transition model.
* Measurement noise: Uncertainty in the observations due to network noise/jitter.
* Kalman gain: Determines how much weight to give to the prediction and measurement.

**5. Adaptivity in OveruseEstimator**

* The OveruseEstimator dynamically adjusts process and measurement noise variances based on network conditions for better accuracy.

**6. Role in OveruseEstimation**

* Estimates inter-arrival time delta offset and noise variance.
* Filters out noise/jitter to provide accurate information for bitrate control.
* Contributes to smooth and efficient video streaming.

### Why the model `t_delta = fs_delta * slope_ + offset` is used in the OveruseEstimator?

 **Here's a breakdown of why the model `t_delta = fs_delta * slope_ + offset` is used in the OveruseEstimator:**

**Key Assumptions:**

1. **Linear Relationship:** The model assumes a linear relationship between the inter-arrival time delta (`t_delta`) and the size delta of the received data packet (`fs_delta`). This means that, on average, larger packets tend to have larger inter-arrival times, and vice versa. This assumption often holds true in network traffic, where larger packets generally take longer to transmit and process.

2. **Non-Zero Offset:** The offset (`offset_`) accounts for the fact that even when a packet has a size of zero, there's still a non-zero inter-arrival time due to factors like network delays, processing overhead, and potential buffering.

3. **Slope as Relative Bandwidth Indicator:** The slope (`slope_`), as discussed earlier, acts as a relative indicator of the available bandwidth. While it's not a direct measure of bandwidth, a steeper positive slope often suggests a lower available bandwidth, as packets are taking longer to arrive.

**Purpose of the Model:**

- **Filtering Noise:** The Kalman filter utilizes this model to estimate the offset and slope while filtering out noise/jitter. This allows it to distinguish between true bandwidth changes and temporary fluctuations, leading to more accurate bitrate adaptation decisions.

- **Tracking Trends:** By tracking the evolution of the slope over time, the OveruseEstimator can detect trends in the available bandwidth and adjust the sending bitrate accordingly. This helps to ensure smooth video streaming and prevent congestion.

**Limitations:**

- **Linearity:** The assumption of a linear relationship might not always hold perfectly, especially in highly dynamic or congested networks.
- **Relative Bandwidth:** The slope only provides a relative indication of bandwidth, not a direct measure.

**Conclusion:**

Despite its limitations, this model provides a useful and adaptable framework for estimating inter-arrival time deltas and filtering out noise in a network environment. Its combination with the Kalman filter and adaptive noise estimation techniques makes it a valuable tool for bitrate adaptation in WebRTC's RBE algorithm, contributing to efficient and stable video streaming.



### Does it estimate bandwidth of sender or receiver?

In the OveruseEstimator described above, it primarily estimates the bandwidth available on the **receiver side**. It does this by analyzing the inter-arrival time of packets received from the sender.

The estimator calculates the difference between the expected and actual arrival times of packets to determine the offset. This offset can be used to infer the available bandwidth on the receiver's network and the level of congestion. By adjusting the sending bitrate based on this estimated bandwidth, the sender can improve the efficiency and quality of the video stream.

While the estimator focuses on the receiver's bandwidth, it indirectly influences the sender's bandwidth as well. The sender adapts its bitrate based on the feedback received from the receiver, which is directly related to the receiver's available bandwidth. This feedback loop helps to ensure that the sender transmits data at a rate that the receiver can handle, preventing congestion and packet loss.

Therefore, although the OveruseEstimator doesn't directly measure the sender's bandwidth, it plays a crucial role in assisting the sender to adjust its transmission rate to the available bandwidth on the receiver's network, ultimately affecting both sides of the communication.

### What does the "slope_" represent?

The "slope_" in the OveruseEstimator is indeed related to the available bandwidth on the receiver side, but it's not a direct measure. Here's a more detailed explanation:

**Relationship between slope and available bandwidth:**

* **Slope:** Represents the estimated rate of change in the inter-arrival time of packets. A steeper positive slope indicates larger inter-arrival times, potentially suggesting a **lower available bandwidth** on the receiver side.
* **Available bandwidth:** Refers to the maximum data transfer rate that the receiver can handle without experiencing congestion and packet loss.

While the slope itself doesn't directly quantify the available bandwidth, it provides an indication of the **relative rate of change** in the available bandwidth. A decreasing slope (becoming less positive) can suggest that the available bandwidth is decreasing and vice versa.

Here's an analogy to illustrate this relationship:

Imagine a road with varying traffic density. The slope can be compared to the **average speed** of cars on the road. When traffic is heavy (low available bandwidth), the average speed decreases, leading to a steeper negative slope. Conversely, when traffic is light (high available bandwidth), the average speed increases, resulting in a flatter slope or even a positive slope if the traffic density is low enough.

Therefore, the slope can be considered a **relative indicator** of the available bandwidth, providing valuable insights for the RBE algorithm to adjust the sending bitrate based on network conditions.

**Additional clarification:**

* While the slope helps estimate the relative bandwidth, it's crucial to consider other factors such as **packet size and network congestion** for a more accurate picture.
* The OveruseEstimator also utilizes other metrics like **offset** and **noise variance** in conjunction with the slope to achieve a comprehensive understanding of the network dynamics and improve bitrate adaptation.

In summary, the slope in the OveruseEstimator is not a direct measure of the available bandwidth but provides valuable information about its relative changes. This information, along with other metrics, helps the RBE algorithm to optimize video streaming performance by dynamically adjusting the sending bitrate.


While the interpretation of "slope_" as an inverse of the available bandwidth is appealing and partially correct, it's not entirely accurate. Here's a more nuanced explanation:

**Relationship between slope and available bandwidth:**

* **Slope:** Represents the estimated rate of change in the **inter-arrival time** of packets.
* **Available bandwidth:** Refers to the maximum **data transfer rate** that the receiver can handle.

While both concepts are related, they measure different aspects of network performance. The slope directly measures the **time interval** between packets, while the available bandwidth measures the **data rate**.

Therefore, the relationship between slope and available bandwidth is **indirect and non-linear**. We cannot simply take the reciprocal of the slope to get the available bandwidth.

**Reasons for non-linearity:**

* The inter-arrival time is influenced not only by the available bandwidth but also by other factors like **packet size, network congestion, and queuing delays**.
* The relationship between inter-arrival time and available bandwidth is not linear, especially when congestion is present.

**Example:**

Imagine two scenarios:

1. **High available bandwidth, low congestion:** In this case, the inter-arrival time between packets will be small (flatter slope) due to the high data transfer rate and efficient transmission.
2. **Low available bandwidth, high congestion:** Here, the inter-arrival time will be significantly larger (steeper negative slope) due to the limited bandwidth and queuing delays caused by congestion.

In both scenarios, the slope provides valuable information about the relative rate of change in the available bandwidth, but it doesn't directly quantify the actual bandwidth value.

**Conclusion:**

The slope in the OveruseEstimator should be interpreted as a **relative indicator** of the available bandwidth, not an exact inverse. It provides valuable insights into network dynamics and aids in bitrate adaptation, but needs to be combined with other metrics for a more accurate understanding of network performance.

### What does the "noise/jitter" represent?

The "noise/jitter" refers to the **random variations in the inter-arrival time of packets** received from the sender. These variations can arise from various factors such as:

* **Network congestion:** When the network is overloaded, packets can experience delays and arrive at irregular intervals.
* **Routing changes:** Packets may take different paths through the network, leading to variations in arrival times.
* **Hardware limitations:** Network devices like routers and switches may introduce slight processing delays, causing jitter.
* **Sender behavior:** If the sender is sending data in bursts, it can create gaps between packets, leading to jitter in the receiver's perspective.

The OveruseEstimator aims to **distinguish between noise/jitter and actual changes in the available bandwidth**. This is crucial because adjusting the sending bitrate based on temporary fluctuations caused by noise/jitter can lead to unnecessary bandwidth usage and unstable video streaming.

Here's how the OveruseEstimator deals with noise/jitter:

* **Kalman filter:** The Kalman filter estimates the state of the system (offset and slope) while simultaneously accounting for the noise/jitter in the observations. This allows the filter to distinguish between true changes in the available bandwidth and random fluctuations.
* **Noise variance:** The OveruseEstimator calculates the variance of the noise/jitter based on the observed deviations from the estimated inter-arrival time. This variance is used by the Kalman filter to adjust its sensitivity and improve the accuracy of the state estimation.
* **Adaptive filtering:** The OveruseEstimator adapts its parameters based on the current bandwidth hypothesis (overusing, underusing, or normal). This allows the filter to become more or less sensitive to noise/jitter depending on the network conditions.

By accounting for and filtering out noise/jitter, the OveruseEstimator can provide a more accurate picture of the available bandwidth and ensure that the RBE algorithm adjusts the sending bitrate effectively, leading to a smooth and efficient video streaming experience.


# Explanation of the OveruseDetector code in WebRTC

This code defines an `OveruseDetector` class in WebRTC that detects network congestion and helps estimate available bandwidth. Here's a breakdown of the key functionalities:

**1. Purpose:**

The `OveruseDetector` aims to detect whether the sending bitrate is exceeding the available network bandwidth, causing congestion and potential packet loss.

**2. Key Concepts:**

* **Offset:** The difference between the estimated and actual inter-arrival time of packets. A positive offset indicates potential overuse.
* **Threshold:** A dynamic value used to determine if the offset indicates overuse.
* **Hypothesis:** The current state of the detector, indicating either normal, underusing, or overusing bandwidth.

**3. Code Breakdown:**

* **Public methods:**
    * **Detect:** Updates the detector state based on the offset, timestamp delta, number of deltas, and current time. Returns the updated hypothesis.
    * **State:** Returns the current hypothesis (normal, underusing, or overusing).
* **Private methods:**
    * **UpdateThreshold:** Adjusts the threshold based on the observed offset and time since the last update.
* **State variables:**
    * `threshold_`: The current threshold for detecting overuse.
    * `last_update_ms_`: Timestamp of the last threshold update.
    * `prev_offset_`: Previously observed offset.
    * `time_over_using_`: Accumulated time spent in "overusing" state.
    * `overuse_counter_`: Number of consecutive "overusing" detections.
    * `hypothesis_`: The current hypothesis about bandwidth usage.

**4. Detection Algorithm:**

* The `Detect` function takes the offset, timestamp delta, number of deltas, and current time as inputs.
* It calculates the total time represented by the deltas (`T`) and compares it to the current threshold.
* If `T` is greater than the threshold, the detector considers it an "overusing" case and updates the internal state accordingly.
* The time spent in "overusing" state and the number of consecutive "overusing" detections are used to confirm the overuse hypothesis.
* Similarly, if `T` is significantly lower than the threshold, the detector might transition to an "underusing" state.
* Otherwise, the detector remains in the "normal" state.

**5. Threshold Adaptation:**

* The `UpdateThreshold` function dynamically adjusts the threshold based on the observed offset and the time elapsed since the last update.
* If the offset is significantly larger than the threshold, the threshold is increased slowly to avoid over-reacting to temporary spikes.
* Conversely, if the offset is much smaller than the threshold, the threshold is decreased faster to adapt to potential bandwidth changes.

**6. Overall Functionality:**

* The `OveruseDetector` provides a dynamic mechanism to detect network congestion based on observed packet arrival times.
* It helps the Remote Bitrate Estimator (RBE) in WebRTC to adapt the sending bitrate to match the available bandwidth and ensure smooth and efficient video streaming.

**7. Additional Notes:**

* The specific values of constants like `kMaxAdaptOffsetMs` and `kOverUsingTimeThreshold` can be adjusted based on specific network conditions and performance requirements.
* The code also includes logging statements for debugging purposes, which can be helpful for analyzing the detector's behavior in different scenarios.

**8. Conclusion:**

Understanding the `OveruseDetector` code provides valuable insights into how WebRTC adapts to network congestion and maintains video quality. This knowledge can be beneficial for developers working with WebRTC and for anyone interested in the technical details of real-time video communication.

## Why equation `T = std::min(num_of_deltas, kMaxNumDeltas) * offset` is used in the OveruseDetector?

 **Here's a breakdown of the equation `T = std::min(num_of_deltas, kMaxNumDeltas) * offset` in the OveruseDetector and its implications:**

**Purpose:**

- This equation calculates a metric `T` that quantifies the overall delay or queuing time observed in the network, primarily caused by congestion.
- It combines information about the number of recent deltas and the estimated offset to make a decision about potential overuse of the available bandwidth.

**Equation Breakdown:**

- `num_of_deltas`: Represents the number of recent inter-arrival time deltas used for estimation.
- `kMaxNumDeltas`: A constant that limits the maximum number of deltas considered, preventing excessive influence from older data.
- `std::min`: Ensures that only a reasonable number of deltas are used, avoiding potential statistical biases.
- `offset`: The estimated offset, indicating the average delay or deviation from expected arrival times.
- `T`: The resulting metric, representing the accumulated delay based on recent observations.

**Overuse Detection Logic:**

- **Threshold Comparison:** The calculated `T` is compared to a predefined threshold.
- **kBwOverusing State:** If `T` exceeds the threshold, it strongly suggests that packets are experiencing significant delays, likely due to congestion and overuse of the available bandwidth. This triggers the `kBwOverusing` state, signaling the need for bitrate reduction.

**Rationale:**

- **Cumulative Delay:** By multiplying the offset with a capped number of deltas, `T` captures the overall delay pattern rather than being overly sensitive to individual fluctuations.
- **Congestion Indicator:** A high `T` value indicates a persistent delay trend, which is a common symptom of congestion and overuse.
- **Bitrate Adaptation:** Triggering the `kBwOverusing` state prompts the RBE algorithm to reduce the sending bitrate, aiming to alleviate congestion and improve network stability.

**Key Points:**

- The equation balances recent observations with a maximum sample size.
- It focuses on accumulated delay rather than instantaneous fluctuations.
- It provides a robust signal for detecting congestion and overuse.
- It informs bitrate adaptation decisions to maintain network stability.

## Why the threshold in the OveruseDetector is restricted to the range [6, 600]?

**Here's an explanation of why the threshold in the OveruseDetector is restricted to the range [6, 600] using `rtc::SafeClamp`:**

**Purpose of Restriction:**

- **Sensitivity Control:** The threshold value determines how sensitive the OveruseDetector is to delay variations and congestion signals. Restricting it within a reasonable range ensures that the detector doesn't become overly sensitive or too insensitive, leading to suboptimal bitrate adaptation decisions.
- **Preventing Extreme Values:** Unbounded thresholds could result in extreme values that might trigger unnecessary bitrate reductions or miss critical congestion signals. Clampling prevents unrealistic thresholds and promotes stable operation.

**Specific Range Choice:**

- **Lower Bound (6):** A threshold below 6 might be overly sensitive, triggering bitrate reductions due to minor fluctuations in delay, potentially hindering video quality unnecessarily.
- **Upper Bound (600):** A threshold above 600 might be too insensitive, failing to detect congestion early enough, leading to potential video freezes and degraded quality.
- **Empirical Selection:** The specific range of [6, 600] has likely been determined through experimentation and analysis of real-world network conditions to strike a balance between sensitivity and stability.

**Benefits of Clampling:**

- **Robustness:** Clampling enhances the detector's robustness to outliers and unexpected delay spikes, preventing erratic behavior.
- **Adaptability:** The OveruseDetector can potentially adjust the threshold dynamically within this range based on network conditions and observed patterns, optimizing its sensitivity over time.
- **Smooth Adaptation:** By confining the threshold to a reasonable range, the RBE algorithm can make smoother bitrate adjustments, avoiding abrupt changes that might impact video quality.

**In summary,**

- Restriction of the threshold using `rtc::SafeClamp` is a crucial safeguard for the OveruseDetector's reliability and effectiveness in bitrate adaptation.
- It ensures that the detector operates within a balanced sensitivity zone, accurately identifying congestion while avoiding false alarms or missed signals.
- This contributes to smoother video streaming experiences and better utilization of available bandwidth.







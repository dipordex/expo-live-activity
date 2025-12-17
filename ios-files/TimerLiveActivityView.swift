//
//  TimerLiveActivityView.swift
//  SetInc
//
//  Created by vipul chauhan on 08/12/25.
//

import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Main Lock Screen View
struct TimerLiveActivityView: View {
  let title: String
  let timer: LiveActivityAttributes.Timer?
  let activityId: String

  var isRunning: Bool { timer?.isRunning ?? false }
  var remaining: Double {
    if #available(iOS 16.2, *) {
      LiveActivityUtil.logMessage("Remaining: \(timer?.remaining ?? 0)")
    } else {
      // Fallback on earlier versions
    }
    return timer?.remaining ?? 0
  }

  // MARK: - Derived Dates
  var startDate: Date {
      if isRunning {
        return Date()
      } else {
        return Date().addingTimeInterval(-(timer?.duration ?? 0 - remaining))
      }
  }

  var endDate: Date {
      Date().addingTimeInterval(remaining)
  }

  var pauseDate: Date? {
      isRunning ? nil : Date()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {

      // Header
      HStack(spacing: 8) {
        Image(systemName: "timer")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.white.opacity(0.9))

        Text(title)
          .font(.title3)
          .foregroundStyle(.white.opacity(0.9))

        if !isRunning {
          PausedTag()
        }
      }

      // Timer content
      HStack(spacing: 16) {
        if isRunning {
          // Auto-updating countdown
          Text(
              timerInterval: startDate...endDate,
              countsDown: true
          )
          .font(.system(size: 28, weight: .semibold, design: .rounded))
          .monospacedDigit()
          .foregroundStyle(.white)
        } else {
          // Static remaining time when paused
          Text(formatTime(remaining))
            .font(.system(size: 28, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
        }

        Spacer()

        if remaining > 0 {
          if isRunning {
            CircleButton(
              symbol: "pause.fill",
              intent: PauseTimerIntent(
                activityId: activityId,
                timerId: timer?.id ?? ""
              )
            )
          } else {
            CircleButton(
              symbol: "play.fill",
              intent: ResumeTimerIntent(
                activityId: activityId,
                timerId: timer?.id ?? ""
              )
            )
          }
        }

        CircleButton(
          symbol: "stop.fill",
          intent: StopTimerIntent(
            activityId: activityId,
            timerId: timer?.id ?? ""
          )
        )
      }
    }
    .padding(20)
    .background(.black.opacity(0.35))
    .clipShape(RoundedRectangle(cornerRadius: 20))
  }
}

// MARK: - Minimal
struct TimerMinimalView: View {
  let isRunning: Bool

  var body: some View {
    ZStack {
      Circle()
        .fill(isRunning ? Color.green : Color.orange)
        .frame(width: 14, height: 14)

      Image(systemName: "timer")
        .font(.system(size: 8, weight: .bold))
        .foregroundStyle(.white)
    }
  }
}

// MARK: - Compact Leading
struct TimerCompactLeadingView: View {
  let remaining: Double

  var body: some View {
    Text(formatTime(remaining))
      .font(.caption)
      .foregroundStyle(.white)
      .monospacedDigit()
  }

  private func formatTime(_ seconds: Double) -> String {
    let sec = max(Int(seconds), 0)
    let m = (sec % 3600) / 60
    let s = sec % 60
    return String(format: "%02d:%02d", m, s)
  }
}

// MARK: - Compact Trailing
struct TimerCompactTrailingView: View {
  let isRunning: Bool

  var body: some View {
    Image(systemName: isRunning ? "pause.fill" : "play.fill")
      .font(.caption2)
      .foregroundStyle(.white.opacity(0.9))
  }
}

// MARK: - Expanded Leading
struct TimerExpandedLeadingView: View {
  let title: String
  let subtitle: String?

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: "timer")
        .font(.headline)
        .foregroundStyle(.white.opacity(0.9))

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.headline)
          .foregroundStyle(.white)

        if let subtitle {
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.white.opacity(0.7))
        }
      }
    }
    .padding(.leading, 5)
  }
}

// MARK: - Expanded Trailing
struct TimerExpandedTrailingView: View {
  let isRunning: Bool

  var body: some View {
    HStack(spacing: 16) {
      CircleButton(symbol: isRunning ? "pause.fill" : "play.fill")
      CircleButton(symbol: "stop.fill")
    }
    .padding(.trailing, 5)
  }
}

// MARK: - Expanded Bottom
struct TimerExpandedBottomView: View {
  let remaining: Double

  var body: some View {
    Text(formatTime(remaining))
      .font(.system(size: 34, weight: .semibold, design: .rounded))
      .foregroundStyle(.white)
      .monospacedDigit()
      .padding(.vertical, 8)
  }

  private func formatTime(_ seconds: Double) -> String {
    let sec = max(Int(seconds), 0)
    let h = sec / 3600
    let m = (sec % 3600) / 60
    let s = sec % 60

    if h > 0 {
      return String(format: "%02d:%02d:%02d", h, m, s)
    } else {
      return String(format: "%02d:%02d", m, s)
    }
  }
}

import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct StopwatchLiveActivityView: View {
  let title: String
  let activityId: String
  let stopwatch: LiveActivityAttributes.Stopwatch?

  var isRunning: Bool { stopwatch?.isRunning ?? false }
  var elapsedText: String { stopwatch?.elapsed ?? "00:00" }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {

      HStack(spacing: 8) {
        Image(systemName: "stopwatch")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.white.opacity(0.9))

        Text(title)
          .font(.title3)
          .foregroundStyle(.white.opacity(0.9))

        if !isRunning {
          PausedTag()
        }
      }

      HStack(spacing: 16) {
        Text(elapsedText)
          .font(.system(size: 28, weight: .semibold, design: .rounded))
          .monospacedDigit()
          .foregroundStyle(.white)

        Spacer()
        if let laps = stopwatch?.lapCount, laps > 0 {
          Text("Lap: \(laps)")
            .font(.system(size: 18, weight: .regular, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
        }

        if isRunning {
          CircleButton(
            symbol: "pause.fill",
            intent: PauseStopwatchIntent(
              activityId: activityId,
              stopwatchId: stopwatch?.id ?? ""
            ),
            deepLink: nil
          )
          
           CircleButton(
            symbol: "flag.fill",
            intent: LapStopwatchIntent(
              activityId: activityId,
              stopwatchId: stopwatch?.id ?? ""
            ),
            deepLink: nil
          )
        } else {
          CircleButton(
            symbol: "play.fill",
            intent: StartStopwatchIntent(
              activityId: activityId,
              stopwatchId: stopwatch?.id ?? ""
            ),
            deepLink: nil
          )
          CircleButton(
            symbol: "arrow.trianglehead.clockwise.rotate.90",
            intent: ResetStopwatchIntent(
              activityId: activityId,
              stopwatchId: stopwatch?.id ?? ""
            ),
            deepLink: nil
          )

        }
      }
    }
    .padding(20)
    .background(.black.opacity(0.35))
    .clipShape(RoundedRectangle(cornerRadius: 20))
  }
}

//
//  StopwatchDynamicIslandViews.swift
//
// MARK: - MINIMAL VIEW
struct StopwatchMinimalView: View {
  let isRunning: Bool

  var body: some View {
    ZStack {
      Circle()
        .fill(isRunning ? Color.green : Color.red)
        .frame(width: 14, height: 14)

      Image(systemName: "stopwatch")
        .font(.system(size: 8, weight: .bold))
        .foregroundStyle(.white)
    }
  }
}

// MARK: - COMPACT LEADING VIEW
struct StopwatchCompactLeadingView: View {
  let elapsed: String

  var body: some View {
    Text(elapsed)
      .font(.caption)
      .foregroundStyle(.white)
      .monospacedDigit()
  }
}

// MARK: - COMPACT TRAILING VIEW
struct StopwatchCompactTrailingView: View {
  let isRunning: Bool

  var body: some View {
    Image(systemName: isRunning ? "pause.fill" : "play.fill")
      .font(.caption2)
      .foregroundStyle(.white.opacity(0.9))
  }
}

// MARK: - EXPANDED LEADING VIEW
struct StopwatchExpandedLeadingView: View {
  let title: String
  let subtitle: String?

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: "stopwatch")
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

// MARK: - EXPANDED TRAILING VIEW
struct StopwatchExpandedTrailingView: View {
  let isRunning: Bool

  var body: some View {
    HStack(spacing: 16) {
      CircleButton(symbol: isRunning ? "pause.fill" : "play.fill")

      if isRunning {
        CircleButton(symbol: "flag.fill")
      }
    }
    .padding(.trailing, 5)
  }
}

// MARK: - EXPANDED BOTTOM VIEW
struct StopwatchExpandedBottomView: View {
  let elapsed: String

  var body: some View {
    Text(elapsed)
      .font(.system(size: 34, weight: .semibold, design: .rounded))
      .foregroundStyle(.white)
      .monospacedDigit()
      .padding(.vertical, 8)
  }
}

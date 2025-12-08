import ActivityKit
import SwiftUI
import WidgetKit

struct LiveActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var title: String
    var subtitle: String?
    var mode: String?
    var stopwatch: Stopwatch?
    var timer: Timer?
  }

  var name: String
  var backgroundColor: String?
  var titleColor: String?
  var subtitleColor: String?
  var progressViewTint: String?
  var progressViewLabelColor: String?
  var deepLinkUrl: String?
  var timerType: DynamicIslandTimerType?
  var padding: Int?
  var paddingDetails: PaddingDetails?
  var imagePosition: String?
  var imageWidth: Int?
  var imageHeight: Int?
  var imageWidthPercent: Double?
  var imageHeightPercent: Double?
  var imageAlign: String?
  var contentFit: String?

  enum DynamicIslandTimerType: String, Codable {
    case circular
    case digital
  }

  struct PaddingDetails: Codable, Hashable {
    var top: Int?
    var bottom: Int?
    var left: Int?
    var right: Int?
    var vertical: Int?
    var horizontal: Int?
  }

  struct Stopwatch: Codable, Hashable {
    var id: String?
    var elapsed: String?
    var isRunning: Bool?
  }

  struct Timer: Codable, Hashable {
    var id: String?
    var duration: Double?
    var remaining: Double?
    var isRunning: Bool?
    var endsAt: Double?
  }
}

struct LiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivityAttributes.self) { context in
      switch context.state.mode {
      case "stopwatch":
        StopwatchLiveActivityView(
          title: context.state.title,
          stopwatch: context.state.stopwatch
        ).activityBackgroundTint(
          context.attributes.backgroundColor.map { Color(hex: $0) }
        )
        .activitySystemActionForegroundColor(Color.black)
        .applyWidgetURL(from: context.attributes.deepLinkUrl)
      case "timer":
        TimerLiveActivityView(
          title: context.state.title,
          timer: context.state.timer
        )
        .activityBackgroundTint(
          context.attributes.backgroundColor.map { Color(hex: $0) }
        )
        .activitySystemActionForegroundColor(Color.black)
        .applyWidgetURL(from: context.attributes.deepLinkUrl)

      default:
        EmptyView()
      }

    } dynamicIsland: { context in
      switch context.state.mode {
      case "stopwatch":
        return buildStopwatchIsland(context: context)
      case "timer":
        return buildTimerIsland(context: context)
      default:
        return buildEmptyIsland()
      }
    }
  }

  // MARK: - STOPWATCH Dynamic Island
  func buildStopwatchIsland(
    context: ActivityViewContext<LiveActivityAttributes>
  ) -> DynamicIsland {
    let stopwatch = context.state.stopwatch
    let isRunning = stopwatch?.isRunning ?? false
    let elapsed = stopwatch?.elapsed ?? "00:00"
    return DynamicIsland {
      // Expanded - Leading
      DynamicIslandExpandedRegion(.leading) {
        StopwatchExpandedLeadingView(
          title: context.state.title,
          subtitle: context.state.subtitle
        )
      }
      // Expanded - Trailing
      DynamicIslandExpandedRegion(.trailing) {
        StopwatchExpandedTrailingView(isRunning: isRunning)
      }
      // Expanded - Bottom
      DynamicIslandExpandedRegion(.bottom) {
        StopwatchExpandedBottomView(elapsed: elapsed)
      }
    } compactLeading: {
      StopwatchCompactLeadingView(elapsed: elapsed)
    } compactTrailing: {
      StopwatchCompactTrailingView(isRunning: isRunning)
    } minimal: {
      StopwatchMinimalView(isRunning: isRunning)
    }
  }

  // MARK: - Single Reusable EMPTY Dynamic Island
  func buildEmptyIsland() -> DynamicIsland {
    DynamicIsland {
      DynamicIslandExpandedRegion(.center) {
        EmptyView()
      }
    } compactLeading: {
      EmptyView()
    } compactTrailing: {
      EmptyView()
    } minimal: {
      EmptyView()
    }
  }

  // MARK: - TIMER Dynamic Island Builder
  func buildTimerIsland(context: ActivityViewContext<LiveActivityAttributes>)
    -> DynamicIsland
  {
    guard let timer = context.state.timer else { return buildEmptyIsland() }
    let title = context.state.title
    let subtitle = context.state.subtitle
    let isRunning = timer.isRunning ?? false
    let remaining = timer.remaining ?? 0

    return DynamicIsland {
      // EXPANDED — Leading
      DynamicIslandExpandedRegion(.leading) {
        TimerExpandedLeadingView(
          title: title,
          subtitle: subtitle
        )
      }
      // EXPANDED — Trailing
      DynamicIslandExpandedRegion(.trailing) {
        TimerExpandedTrailingView(isRunning: isRunning)
      }
      // EXPANDED — Bottom
      DynamicIslandExpandedRegion(.bottom) {
        TimerExpandedBottomView(remaining: remaining)
      }
    } compactLeading: {
      TimerCompactLeadingView(remaining: remaining)
    } compactTrailing: {
      TimerCompactTrailingView(isRunning: isRunning)
    } minimal: {
      TimerMinimalView(isRunning: isRunning)
    }
  }
}

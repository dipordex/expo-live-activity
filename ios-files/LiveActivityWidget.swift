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
    var task: Task?
    var showInDynamicIsland: Bool?

    init(
      title: String,
      subtitle: String? = nil,
      mode: String? = nil,
      stopwatch: Stopwatch? = nil,
      timer: Timer? = nil,
      task: Task? = nil,
      showInDynamicIsland: Bool? = nil
    ) {
      self.title = title
      self.subtitle = subtitle
      self.mode = mode
      self.stopwatch = stopwatch
      self.timer = timer
      self.task = task
      self.showInDynamicIsland = showInDynamicIsland
    }
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
  var apiEndpoint: ApiEndpoint?
  var accessToken: String?

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
    var id: String
    var startedAt: Date?
    var accumulated: TimeInterval
    var isRunning: Bool
    var lapCount: Int

    init(
      id: String,
      startedAt: Date? = Date(),
      accumulated: TimeInterval = 0,
      isRunning: Bool,
      lapCount: Int = 0
    ) {
      self.id = id
      self.startedAt = startedAt
      self.accumulated = accumulated
      self.isRunning = isRunning
      self.lapCount = lapCount
    }
  }

  struct Task: Codable, Hashable {
    var id: String?
    var startDate: Date?

    init(id: String? = nil, startDate: Date? = Date()) {
      self.id = id
      self.startDate = startDate
    }
  }

  struct Timer: Codable, Hashable {
    var id: String?
    var duration: Double?
    var remaining: Double?
    var isRunning: Bool?
    var endsAt: Date?
    var startTime: Date?
  }

  struct ApiEndpoint: Codable, Hashable {
    var stopwatchEndpoints: StopwatchEndpoints?
    var taskEndpoints: String?
  }

  struct StopwatchEndpoints: Codable, Hashable {
    var common: String
    var lap: String
  }
}
@available(iOS 16.2, *)
struct LiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivityAttributes.self) { context in
      switch context.state.mode {
      case "stopwatch":
        StopwatchLiveActivityView(
          title: context.state.title,
          activityId: context.activityID,
          stopwatch: context.state.stopwatch
        ).activityBackgroundTint(
          context.attributes.backgroundColor.map { Color(hex: $0) }
        )
        .activitySystemActionForegroundColor(Color.black)
        .applyWidgetURL(from: context.attributes.deepLinkUrl)
      case "timer":
        TimerLiveActivityView(
          title: context.state.title,
          timer: context.state.timer,
          activityId: context.activityID
        )
        .activityBackgroundTint(
          context.attributes.backgroundColor.map { Color(hex: $0) }
        )
        .activitySystemActionForegroundColor(Color.black)
        .applyWidgetURL(from: context.attributes.deepLinkUrl)
      case "task":
        TaskLiveActivityView(
          title: context.state.title,
          subtitle: context.state.subtitle,
          activityId: context.activityID,
          task: context.state.task
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
      if context.state.showInDynamicIsland == false {
        return buildEmptyIsland()
      }
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
    let startedAt = stopwatch?.startedAt ?? Date()
    let accumulated = stopwatch?.accumulated ?? 0
    let activityId = context.activityID

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
        StopwatchExpandedTrailingView(
          isRunning: isRunning,
          activityId: activityId,
          stopwatchId: stopwatch?.id ?? ""
        )
      }
      // Expanded - Bottom
      DynamicIslandExpandedRegion(.bottom) {
        StopwatchExpandedBottomView(
          isRunning: isRunning,
          startDate: startedAt,
          accumulated: accumulated
        )
      }
    } compactLeading: {
      StopwatchCompactLeadingView(
        isRunning: isRunning,
        startDate: startedAt,
        accumulated: accumulated
      )
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

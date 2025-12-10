//
//  StopwatchIntent.swift
//  SetInc
//

import ActivityKit
import AppIntents
import Foundation

// MARK: - Base Darwin Sender

private func postDarwinNotification(
  activityId: String,
  stopwatchId: String,
  action: String
) {
  let defaults = UserDefaults(suiteName: "group.setInc.app.shared")

  let payload: [String: String] = [
    "activityId": activityId,
    "stopwatchId": stopwatchId,
    "action": action,
    "mode": "stopwatch"
  ]

  defaults?.set(payload, forKey: "LA_Payload")

  CFNotificationCenterPostNotification(
    CFNotificationCenterGetDarwinNotifyCenter(),
    CFNotificationName("setInc.app.liveactivity.button" as CFString),
    nil,
    nil,
    true
  )
}

// MARK: - Start Intent

struct StartStopwatchIntent: AppIntent {

  static var title: LocalizedStringResource = "Start"

  @Parameter(title: "Activity ID")
  var activityId: String

  @Parameter(title: "Stopwatch ID")
  var stopwatchId: String

  init() {}

  init(activityId: String, stopwatchId: String) {
    self.activityId = activityId
    self.stopwatchId = stopwatchId
  }

  func perform() async throws -> some IntentResult {
    postDarwinNotification(
      activityId: activityId,
      stopwatchId: stopwatchId,
      action: "start"
    )
    return .result()
  }
}

// MARK: - Pause Intent

struct PauseStopwatchIntent: AppIntent {
  static var title: LocalizedStringResource = "Pause"

  @Parameter(title: "Activity ID")
  var activityId: String

  @Parameter(title: "Stopwatch ID")
  var stopwatchId: String

  init() {}
  init(activityId: String, stopwatchId: String) {
    self.activityId = activityId
    self.stopwatchId = stopwatchId
  }

  func perform() async throws -> some IntentResult {
    postDarwinNotification(
      activityId: activityId,
      stopwatchId: stopwatchId,
      action: "pause"
    )
    return .result()
  }
}

// MARK: - Lap Intent

struct LapStopwatchIntent: AppIntent {
  static var title: LocalizedStringResource = "Lap"

  @Parameter(title: "Activity ID")
  var activityId: String

  @Parameter(title: "Stopwatch ID")
  var stopwatchId: String

  init() {}
  init(activityId: String, stopwatchId: String) {
    self.activityId = activityId
    self.stopwatchId = stopwatchId
  }

  func perform() async throws -> some IntentResult {
    postDarwinNotification(
      activityId: activityId,
      stopwatchId: stopwatchId,
      action: "lap"
    )
    return .result()
  }
}


// MARK: - Reset Intent

struct ResetStopwatchIntent: AppIntent {
  static var title: LocalizedStringResource = "Reset"
  @Parameter(title: "Activity ID")
  var activityId: String
  @Parameter(title: "Stopwatch ID")
  var stopwatchId: String
  init() {}
  init(activityId: String, stopwatchId: String) {
    self.activityId = activityId
    self.stopwatchId = stopwatchId
  }

  func perform() async throws -> some IntentResult {
    postDarwinNotification(
      activityId: activityId,
      stopwatchId: stopwatchId,
      action: "reset"
    )
    return .result()
  }
}

//
//  TimerIntent.swift
//  LiveActivity
//
//  Created by New MacMini2024 on 10/12/25.
//

import ActivityKit
import AppIntents
import Foundation

// MARK: - Base Darwin Sender

private func postDarwinNotification(
  activityId: String,
  timerId: String,
  action: String
) {
  let defaults = UserDefaults(suiteName: "group.setInc.app.shared")

  let payload: [String: String] = [
    "activityId": activityId,
    "timerId": timerId,
    "action": action,
    "mode": "timer",
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

struct ResumeTimerIntent: AppIntent {

  static var title: LocalizedStringResource = "Resume"

  @Parameter(title: "Activity ID")
  var activityId: String

  @Parameter(title: "Timer ID")
  var timerId: String

  init() {}

  init(activityId: String, timerId: String) {
    self.activityId = activityId
    self.timerId = timerId
  }

  func perform() async throws -> some IntentResult {
    postDarwinNotification(
      activityId: activityId,
      timerId: timerId,
      action: "resume"
    )
    return .result()
  }
}

// MARK: - Pause Intent

struct PauseTimerIntent: AppIntent {
  static var title: LocalizedStringResource = "Pause"

  @Parameter(title: "Activity ID")
  var activityId: String

  @Parameter(title: "Timer ID")
  var timerId: String

  init() {}
  init(activityId: String, timerId: String) {
    self.activityId = activityId
    self.timerId = timerId
  }

  func perform() async throws -> some IntentResult {
    postDarwinNotification(
      activityId: activityId,
      timerId: timerId,
      action: "pause"
    )
    return .result()
  }
}

// MARK: - Reset Intent

struct StopTimerIntent: AppIntent {
  static var title: LocalizedStringResource = "Stop"
  @Parameter(title: "Activity ID")
  var activityId: String
  @Parameter(title: "Timer ID")
  var timerId: String
  init() {}
  init(activityId: String, timerId: String) {
    self.activityId = activityId
    self.timerId = timerId
  }

  func perform() async throws -> some IntentResult {
    postDarwinNotification(
      activityId: activityId,
      timerId: timerId,
      action: "stop"
    )
    return .result()
  }
}

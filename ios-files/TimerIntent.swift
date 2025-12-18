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

struct ResumeTimerIntent: LiveActivityIntent {

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

struct PauseTimerIntent: LiveActivityIntent {
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
    guard #available(iOS 17.0, *) else { return .result() }
    guard let (state, _) =
              LiveActivityUtil.getCurrentStateData(for: "timer", id: activityId),
            let timer = state.timer
    else { return .result() }
      let now = Date()
      if let endTime = timer.endsAt, now >= endTime {
        LiveActivityUtil.logMessage("Skipping pause as it's already past the end time.")
          return .result()
      }
      postDarwinNotification(
          activityId: activityId,
          timerId: timerId,
          action: "pause"
      )
      return .result()
  }
}

// MARK: - Reset Intent

struct StopTimerIntent: LiveActivityIntent {
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

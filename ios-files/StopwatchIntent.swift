//
//  StopwatchIntent.swift
//  SetInc
//

import ActivityKit
import AppIntents
import Foundation

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
  
// MARK: - API RESPONSE MODEL
struct StopwatchAPIResponse: Codable {
  let id: Int
  let status: String
  let countdown_duration: String?
  let start_time: String?
  let message: String?
}
struct CreateLapPayload: Encodable {
  let name: String
  let duration: Int
  let stopwatch: Int
}

struct LapAPIResponse: Codable {
  let id: Int
  let name: String
  let duration: String
  let stopwatch: Int
}

// MARK: - Error Code
// 0000 - missing endpoint
// 0001 - missisng accesstoken
// 0002 - invalid response

// MARK: - API HELPER (USED BY ALL INTENTS)

final class StopwatchAPI {
  static func call<T: Codable>(
    attributes: LiveActivityAttributes,
    stopwatchId: String,
    action: String,
    method: HTTPMethod = .POST,
    body: Data? = nil,
    responseType: T.Type
  ) async throws -> T {

    // MARK: - Validations
    guard let apiEndpoints = attributes.apiEndpoint?.stopwatchEndpoints else {
      throw APIError.custom(
        code: "0000",
        message: "Stopwatch API endpoints are missing"
      )
    }
    guard let accessToken = attributes.accessToken, !accessToken.isEmpty else {
      throw APIError.custom(code: "0001", message: "Access token is missing")
    }
    // MARK: - Select Endpoint
    // Decide which endpoint to use based on action
    let isLap = action.lowercased() == "lap"

    // MARK: - URL
    let url: String
    if isLap {
      url = "\(apiEndpoints.lap)/"
    } else {
      url = "\(apiEndpoints.common)/\(stopwatchId)/?status=\(action)"
    }
    // MARK: - Request
    let request = APIRequest(
      url: url,
      method: method,
      headers: [
        "Authorization": "Bearer \(accessToken)",
        "Content-Type": "application/json",
      ],
      body: body
    )

    // MARK: - Network Call
    let response = try await APIClient.shared.request(
      request,
      responseType: T.self
    )
    return response
  }
}

// MARK: - LIVE ACTIVITY UPDATE HELPER

final class StopwatchLiveActivityUpdater {
  static func buildState(
    oldState: LiveActivityAttributes.ContentState,
    stopwatch: LiveActivityAttributes.Stopwatch
  ) -> LiveActivityAttributes.ContentState {
    LiveActivityAttributes.ContentState(
      title: oldState.title,
      subtitle: oldState.subtitle,
      mode: oldState.mode,
      stopwatch: stopwatch,
      showInDynamicIsland: oldState.showInDynamicIsland
    )
  }

  @available(iOS 16.2, *)
  static func update(
    activityId: String,
    state: LiveActivityAttributes.ContentState
  ) {
    LiveActivityUtil.updateLiveActivity(
      for: "stopwatch",
      id: activityId,
      contentState: state
    )
  }
}

// MARK: - START / RESUME

struct StartStopwatchIntent: LiveActivityIntent {

  static var title: LocalizedStringResource = "Start"

  @Parameter(title: "Activity ID") var activityId: String
  @Parameter(title: "Stopwatch ID") var stopwatchId: String

  static var openAppWhenRun = false
  static var isDiscoverable = false

  init() {}
  init(activityId: String, stopwatchId: String) {
    self.activityId = activityId
    self.stopwatchId = stopwatchId
  }

  func perform() async throws -> some IntentResult {

    guard #available(iOS 17.0, *) else { return .result() }

    guard
      let (state, attributes) =
        LiveActivityUtil.getCurrentStateData(for: "stopwatch", id: activityId),
      state.stopwatch?.isRunning != true
    else { return .result() }

    do {
      let startResult = try await StopwatchAPI.call(
        attributes: attributes,
        stopwatchId: stopwatchId,
        action: "start",
        responseType: StopwatchAPIResponse.self
      )
      LiveActivityUtil.logMessage("Start successful: \(startResult)")
      let prev = state.stopwatch
      let startedAtDate =
        Date.fromISO8601(startResult.start_time ?? "") ?? Date()
      let newStopwatch = LiveActivityAttributes.Stopwatch(
        id: stopwatchId,
        startedAt: startedAtDate,
        accumulated: prev?.accumulated ?? 0,
        isRunning: true,
        lapCount: prev?.lapCount ?? 0
      )

      StopwatchLiveActivityUpdater.update(
        activityId: activityId,
        state: StopwatchLiveActivityUpdater.buildState(
          oldState: state,
          stopwatch: newStopwatch
        )
      )
      postDarwinNotification(
        activityId: activityId,
        stopwatchId: stopwatchId,
        action: "start"
      )

    } catch {
      LiveActivityUtil.logMessage("Start error: \(error.localizedDescription)")
    }

    return .result()
  }
}

// MARK: - PAUSE

struct PauseStopwatchIntent: LiveActivityIntent {

  static var title: LocalizedStringResource = "Pause"

  @Parameter(title: "Activity ID") var activityId: String
  @Parameter(title: "Stopwatch ID") var stopwatchId: String

  static var openAppWhenRun = false
  static var isDiscoverable = false

  init() {}
  init(activityId: String, stopwatchId: String) {
    self.activityId = activityId
    self.stopwatchId = stopwatchId
  }

  func perform() async throws -> some IntentResult {

    guard #available(iOS 17.0, *) else { return .result() }

    guard
      let (state, attributes) =
        LiveActivityUtil.getCurrentStateData(for: "stopwatch", id: activityId),
      let sw = state.stopwatch,
      let startedAt = sw.startedAt,
      sw.isRunning
    else { return .result() }

    do {
      let pauseResult = try await StopwatchAPI.call(
        attributes: attributes,
        stopwatchId: stopwatchId,
        action: "stop",
        responseType: StopwatchAPIResponse.self
      )
      LiveActivityUtil.logMessage("Pause successful: \(pauseResult)")
      let elapsed =
        Double(pauseResult.countdown_duration ?? "0") ?? sw.accumulated
        + Date().timeIntervalSince(startedAt)
      let newStopwatch = LiveActivityAttributes.Stopwatch(
        id: stopwatchId,
        startedAt: nil,
        accumulated: elapsed,
        isRunning: false,
        lapCount: sw.lapCount
      )

      StopwatchLiveActivityUpdater.update(
        activityId: activityId,
        state: StopwatchLiveActivityUpdater.buildState(
          oldState: state,
          stopwatch: newStopwatch
        )
      )
      postDarwinNotification(
        activityId: activityId,
        stopwatchId: stopwatchId,
        action: "pause"
      )
    } catch {
      LiveActivityUtil.logMessage("Paused error: \(error.localizedDescription)")
    }

    return .result()
  }
}

// MARK: - LAP

struct LapStopwatchIntent: LiveActivityIntent {

  static var title: LocalizedStringResource = "Lap"

  @Parameter(title: "Activity ID") var activityId: String
  @Parameter(title: "Stopwatch ID") var stopwatchId: String

  static var openAppWhenRun = false
  static var isDiscoverable = false

  init() {}
  init(activityId: String, stopwatchId: String) {
    self.activityId = activityId
    self.stopwatchId = stopwatchId
  }

  func perform() async throws -> some IntentResult {

    guard #available(iOS 17.0, *) else { return .result() }

    guard
      let (state, attributes) =
        LiveActivityUtil.getCurrentStateData(for: "stopwatch", id: activityId),
      var sw = state.stopwatch
    else { return .result() }

    do {
      let elapsedSeconds =
        sw.accumulated
        + (sw.isRunning ? Date().timeIntervalSince(sw.startedAt ?? Date()) : 0)
      let lap = sw.lapCount + 1
      sw.lapCount = lap

      let payload = CreateLapPayload(
        name: "Lap \(lap)",
        duration: Int(elapsedSeconds),
        stopwatch: Int(stopwatchId) ?? 0
      )
      let bodyData = try JSONEncoder().encode(payload)
      let lapResult = try await StopwatchAPI.call(
        attributes: attributes,
        stopwatchId: stopwatchId,
        action: "lap",
        body: bodyData,
        responseType: LapAPIResponse.self
      )
      LiveActivityUtil.logMessage("Lap successful: \(lapResult)")

      StopwatchLiveActivityUpdater.update(
        activityId: activityId,
        state: StopwatchLiveActivityUpdater.buildState(
          oldState: state,
          stopwatch: sw
        )
      )
      postDarwinNotification(
        activityId: activityId,
        stopwatchId: stopwatchId,
        action: "lap"
      )
    } catch {
      LiveActivityUtil.logMessage("Lap error: \(error.localizedDescription)")
    }
    return .result()
  }
}

// MARK: - RESET

struct ResetStopwatchIntent: LiveActivityIntent {

  static var title: LocalizedStringResource = "Reset"

  @Parameter(title: "Activity ID") var activityId: String
  @Parameter(title: "Stopwatch ID") var stopwatchId: String

  static var openAppWhenRun = false
  static var isDiscoverable = false

  init() {}
  init(activityId: String, stopwatchId: String) {
    self.activityId = activityId
    self.stopwatchId = stopwatchId
  }

  func perform() async throws -> some IntentResult {

    guard #available(iOS 17.0, *) else { return .result() }

    guard
      let (state, attributes) =
        LiveActivityUtil.getCurrentStateData(for: "stopwatch", id: activityId)
    else { return .result() }

    do {
      let resetResult = try await StopwatchAPI.call(
        attributes: attributes,
        stopwatchId: stopwatchId,
        action: "reset",
        responseType: StopwatchAPIResponse.self
      )
      LiveActivityUtil.logMessage("Reset result: \(resetResult)")
      let newStopwatch = LiveActivityAttributes.Stopwatch(
        id: stopwatchId,
        startedAt: nil,
        accumulated: 0,
        isRunning: false,
        lapCount: 0
      )

      StopwatchLiveActivityUpdater.update(
        activityId: activityId,
        state: StopwatchLiveActivityUpdater.buildState(
          oldState: state,
          stopwatch: newStopwatch
        )
      )
      postDarwinNotification(
        activityId: activityId,
        stopwatchId: stopwatchId,
        action: "reset"
      )
    } catch {
      LiveActivityUtil.logMessage("Reset error: \(error.localizedDescription)")
    }

    return .result()
  }
}

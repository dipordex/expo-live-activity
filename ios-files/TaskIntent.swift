//
//  TaskIntent.swift
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
  taskId: String,
  action: String
) {
  let defaults = UserDefaults(suiteName: "group.setInc.app.shared")

  let payload: [String: String] = [
    "activityId": activityId,
    "taskId": taskId,
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

// MARK: - Models

struct TaskAPIResponse: Codable {
  let category: TaskCategory
  let currentTrackedDuration: String
  let id: Int
  let isTrackingCurrentUser: Bool
  let participants: [TaskParticipant]
  let startTrackedTime: String?
  let timeDifference: Int
  let title: String
  let trackedByUser: String?
  let trackedTime: String
}

struct TaskCategory: Codable {
  let id: Int
  let name: String
}

struct TaskParticipant: Codable {
  let id: Int
  let name: String
  let role: String
}

// MARK: - Task API

final class TaskAPI {

  static func call<T>(
    attributes: LiveActivityAttributes,
    taskId: String,
    action: String = "stop",
    method: HTTPMethod = .POST,
    body: Data? = nil,
    responseType: T.Type
  ) async throws -> T {

    // MARK: - Validations
    guard let apiEndpoint = attributes.apiEndpoint?.taskEndpoints else {
      throw APIError.custom(
        code: "0000",
        message: "Task API endpoints are missing"
      )
    }

    guard let accessToken = attributes.accessToken,
      !accessToken.isEmpty
    else {
      throw APIError.custom(
        code: "0001",
        message: "Access token is missing"
      )
    }

    // MARK: - URL
    let url = "\(apiEndpoint)/\(taskId)/\(action)/"

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
      responseType: T.self,
      shouldDecode: false
    )

    return response
  }
}

// MARK: - Stop Intent

struct StopTaskIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Stop"
  @Parameter(title: "Activity ID")
  var activityId: String
  @Parameter(title: "Timer ID")
  var taskId: String
  init() {}
  init(activityId: String, taskId: String) {
    self.activityId = activityId
    self.taskId = taskId
  }

  func perform() async throws -> some IntentResult {

    guard #available(iOS 17.0, *) else { return .result() }
    guard
      let (state, attributes) =
        LiveActivityUtil.getCurrentStateData(for: "task", id: activityId)
    else {
      return .result()
    }

    do {
      //  Call Stop API (No decoding required)
      _ = try await TaskAPI.call(
        attributes: attributes,
        taskId: taskId,
        action: "stop",
        responseType: Void.self
      )

      LiveActivityUtil.logMessage("Task stop success")

      //  End Live Activity
      LiveActivityUtil.endLiveActivity(
        for: "task",
        id: activityId,
        contentState: state,
        immediate: true
      )

      //        Optional Darwin notify
//      postDarwinNotification(
//        activityId: activityId,
//        taskId: taskId,
//        action: "stop"
//      )

    } catch {
      LiveActivityUtil.logMessage(
        "Task stop error: \(error.localizedDescription)"
      )
    }

    return .result()
  }
}

//
//  TapInIntent.swift
//  LiveActivity
//

import ActivityKit
import AppIntents
import Foundation

// MARK: - Base Darwin Sender
private func postDarwinNotification(
  activityId: String,
  tapInId: String,
  action: String
) {
  let defaults = UserDefaults(suiteName: "group.setInc.app.shared")
  let payload: [String: String] = [
    "activityId": activityId,
    "tapInId": tapInId,
    "action": action,
    "mode": "tapin",
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

struct TapInAPIResponse: Codable {
  let id: Int
  let title: String?
  let trackedTime: String?
}

// MARK: - TapIn API

final class TapInAPI {

  static func call<T>(
    attributes: LiveActivityAttributes,
    tapInId: String,
    action: String = "stop",
    method: HTTPMethod = .POST,
    body: Data? = nil,
    responseType: T.Type
  ) async throws -> T {

    // MARK: - Validations
    guard let apiEndpoint = attributes.apiEndpoint?.tapInEndpoints else {
      throw APIError.custom(
        code: "0000",
        message: "TapIn API endpoints are missing"
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
    let url = "\(apiEndpoint)/\(tapInId)/\(action)"
    if #available(iOS 16.2, *) {
      LiveActivityUtil.logMessage("Hitting TapIn URL: \(url)")
    } else {
      // Fallback on earlier versions
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
      responseType: T.self,
      shouldDecode: false
    )

    return response
  }
}

// MARK: - Stop Intent

struct StopTapInIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Stop"
  @Parameter(title: "Activity ID")
  var activityId: String
  @Parameter(title: "TapIn ID")
  var tapInId: String
  
  init() {}
  init(activityId: String, tapInId: String) {
    self.activityId = activityId
    self.tapInId = tapInId
  }

  func perform() async throws -> some IntentResult {

    guard #available(iOS 17.0, *) else { return .result() }
    guard
      let (state, attributes) =
        LiveActivityUtil.getCurrentStateData(for: "tapin", id: activityId)
    else {
      return .result()
    }

    do {
      //  Call Stop API (No decoding required)
      _ = try await TapInAPI.call(
        attributes: attributes,
        tapInId: tapInId,
        action: "stop",
        responseType: Void.self
      )

      LiveActivityUtil.logMessage("TapIn stop success")

      //  End Live Activity
      LiveActivityUtil.endLiveActivity(
        for: "tapin",
        id: activityId,
        contentState: state,
        immediate: true
      )

    } catch {
      LiveActivityUtil.logMessage(
        "TapIn stop error: \(error.localizedDescription)"
      )
    }

    return .result()
  }
}

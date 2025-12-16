//
//  LiveActivityUtil.swift
//  SetInc
//
//  Created by vipul chauhan on 15/12/25.
//

import ActivityKit
import Foundation
import os.log

@available(iOS 16.2, *)
class LiveActivityUtil {
    
    // MARK: - Logger
  private static let log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.example.setinc", category: "LiveActivity")
  
  static func logMessage(_ message: String, type: OSLogType = .default) {
    os_log("SetInc_Log ==> %{public}@", log: log, type: type, message)
  }
    
    // MARK: - Live Activity State
  static func getCurrentStateData(for mode: String, id: String) -> (state: LiveActivityAttributes.ContentState, activity: LiveActivityAttributes)? {
    logMessage("Fetching current state for mode: \(mode), id: \(id)", type: .info)
    guard let activity = getLiveActivity(for: mode, id: id) else {
      logMessage("No live activity found for id: \(id), mode: \(mode)", type: .error)
      return nil
    }
    logMessage("Found live activity: \(activity), state: \(activity.content.state)", type: .info)
    return (activity.content.state, activity.attributes)
  }
    
    // MARK: - Get Live Activity
  static func getLiveActivity(for mode: String, id: String) -> Activity<LiveActivityAttributes>? {
    logMessage("Searching live activities for mode: \(mode), id: \(id)", type: .info)
    let activity = Activity<LiveActivityAttributes>.activities.first {
      $0.content.state.mode == mode && String($0.id) == id
    }
    if let activity = activity {
      logMessage("Live activity found: \(activity)", type: .info)
    } else {
      logMessage("No live activity found", type: .error)
    }
    return activity
  }
    
    // MARK: - Update Live Activity
  static func updateLiveActivity(for mode: String, id: String, contentState state: LiveActivityAttributes.ContentState) {
    logMessage("Attempting to update live activity for id: \(id), mode: \(mode) with state: \(state)", type: .info)
    guard let activity = getLiveActivity(for: mode, id: id) else {
      logMessage("Cannot update, live activity not found for id: \(id), mode: \(mode)", type: .error)
      return
    }
    let content = ActivityContent(state: state, staleDate: nil)
    Task {
      await activity.update(content)
      logMessage("Live activity updated successfully for id: \(id), mode: \(mode)", type: .info)
    }
  }
    
    // MARK: - Start Live Activity
  static func startLiveActivity(for activityData: LiveActivityAttributes, state contentState: LiveActivityAttributes.ContentState) -> Activity<LiveActivityAttributes>? {
    logMessage("Starting live activity with state: \(contentState)", type: .info)
    do {
      let content = ActivityContent(state: contentState, staleDate: Date(timeIntervalSinceNow: 10))
      let activity = try Activity<LiveActivityAttributes>.request(attributes: activityData, content: content)
      logMessage("Live activity started successfully: \(activity)", type: .info)
      return activity
    } catch {
      logMessage("Error starting live activity: \(error)", type: .error)
      return nil
    }
  }
}

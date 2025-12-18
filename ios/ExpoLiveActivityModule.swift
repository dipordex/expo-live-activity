import ActivityKit
import ExpoModulesCore
import os.log

public class ExpoLiveActivityModule: Module {
    
    // MARK: - Logger
  private static let log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.example.setinc", category: "ExpoLiveActivityModule")
  
  static func logMessage(_ message: String, type: OSLogType = .error) {
    os_log("SetInc_Log ==> %{public}@", log: log, type: type, message)
  }
    
    struct LiveActivityState: Record {
        @Field var title: String?
        @Field var subtitle: String?
        @Field var mode: String?
        @Field var stopwatch: Stopwatch?
        @Field var timer: Timer?
        @Field var showInDynamicIsland: Bool?

        struct Stopwatch: Record {
            @Field var id: String
            @Field var startedAt: Date?
            @Field var accumulated: TimeInterval
            @Field var isRunning: Bool
            @Field var lapCount: Int
        }
        struct Timer: Record {
            @Field var id: String?
            @Field var duration: Double?
            @Field var remaining: Double?
            @Field var isRunning: Bool?
            @Field var endsAt: Date?
            @Field var startTime: Date?
        }
    }

    struct LiveActivityConfig: Record {
        @Field var backgroundColor: String?
        @Field var titleColor: String?
        @Field var subtitleColor: String?
        @Field var progressViewTint: String?
        @Field var progressViewLabelColor: String?
        @Field var deepLinkUrl: String?
        @Field var timerType: DynamicIslandTimerType?
        @Field var padding: Int?
        @Field var paddingDetails: PaddingDetails?
        @Field var imagePosition: String?
        @Field var imageWidth: Int?
        @Field var imageHeight: Int?
        @Field var imageWidthPercent: Double?
        @Field var imageHeightPercent: Double?
        @Field var imageAlign: String?
        @Field var contentFit: String?
        @Field var apiEndpoint: ApiEndpoint?
        @Field var accessToken: String?

        struct PaddingDetails: Record {
            @Field var top: Int?
            @Field var bottom: Int?
            @Field var left: Int?
            @Field var right: Int?
            @Field var vertical: Int?
            @Field var horizontal: Int?
        }
        
        struct ApiEndpoint: Record {
            @Field var stopwatchEndpoints: StopwatchEndpoints?
        }
        
        struct StopwatchEndpoints: Record {
            @Field var common: String
            @Field var lap: String
        }
    }

    enum DynamicIslandTimerType: String, Enumerable {
        case circular
        case digital
    }

    @available(iOS 16.1, *)
    private func sendPushToken(
        activity: Activity<LiveActivityAttributes>,
        activityPushToken: String
    ) {
        sendEvent(
            "onTokenReceived",
            [
                "activityID": activity.id,
                "activityName": activity.attributes.name,
                "activityPushToken": activityPushToken,
            ]
        )
    }

    private func sendPushToStartToken(activityPushToStartToken: String) {
        sendEvent(
            "onPushToStartTokenReceived",
            [
                "activityPushToStartToken": activityPushToStartToken
            ]
        )
    }

    @available(iOS 16.1, *)
    private func sendStateChange(
        activity: Activity<LiveActivityAttributes>,
        activityState: ActivityState
    ) {
        sendEvent(
            "onStateChange",
            [
                "activityID": activity.id,
                "activityName": activity.attributes.name,
                "activityState": String(describing: activityState),
            ]
        )
    }

    //    private func updateImages(
    //        state: LiveActivityState,
    //        newState: inout LiveActivityAttributes.ContentState
    //    ) async throws {
    //        if let name = state.imageName {
    //            newState.imageName = try await resolveImage(from: name)
    //        }
    //
    //        if let name = state.dynamicIslandImageName {
    //            newState.dynamicIslandImageName = try await resolveImage(from: name)
    //        }
    //    }
    
    private func observePushToStartToken() {
        guard #available(iOS 17.2, *),
            ActivityAuthorizationInfo().areActivitiesEnabled
        else { return }

        print("Observing push to start token updates...")
        Task {
            for await data in Activity<LiveActivityAttributes>
                .pushToStartTokenUpdates
            {
                let token = data.reduce("") { $0 + String(format: "%02x", $1) }
                sendPushToStartToken(activityPushToStartToken: token)
            }
        }
    }

    private func observeLiveActivityUpdates() {
        guard #available(iOS 16.2, *) else { return }

        Task {
            for await activityUpdate in Activity<LiveActivityAttributes>
                .activityUpdates
            {
                let activityId = activityUpdate.id
                let activityState = activityUpdate.activityState

                print(
                    "Received activity update: \(activityId), \(activityState)"
                )

                guard
                    let activity = Activity<LiveActivityAttributes>.activities
                        .first(where: {
                            $0.id == activityId
                        })
                else {
                    return print("Didn't find activity with ID \(activityId)")
                }

                if case .active = activityState {
                    Task {
                        for await state in activity.activityStateUpdates {
                            sendStateChange(
                                activity: activity,
                                activityState: state
                            )
                        }
                    }

                    if pushNotificationsEnabled {
                        print(
                            "Adding push token observer for activity \(activity.id)"
                        )
                        Task {
                            for await pushToken in activity.pushTokenUpdates {
                                let pushTokenString = pushToken.reduce("") {
                                    $0 + String(format: "%02x", $1)
                                }

                                sendPushToken(
                                    activity: activity,
                                    activityPushToken: pushTokenString
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    private var pushNotificationsEnabled: Bool {
        Bundle.main.object(
            forInfoDictionaryKey: "ExpoLiveActivity_EnablePushNotifications"
        ) as? Bool
            ?? false
    }

    func observeDarwinNotifications() {
        ExpoLiveActivityModule.logMessage("Registering Darwin notification observer")
        let callback: CFNotificationCallback = { _, _, name, _, _ in
            let notificationName = name?.rawValue as String? ?? "unknown"
            ExpoLiveActivityModule.logMessage("Darwin notification received: \(notificationName)")
            DispatchQueue.main.async {
                ExpoLiveActivityModule.logMessage("Reading App Group payload on main thread")
                ExpoLiveActivityModule.shared?.readAppGroupPayload()
            }
        }
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            callback,
            "setInc.app.liveactivity.button" as CFString,
            nil,
            .deliverImmediately
        )
        ExpoLiveActivityModule.logMessage("Darwin observer added successfully")
    }

    @objc
    func readAppGroupPayload() {
        ExpoLiveActivityModule.logMessage("Attempting to read App Group payload")
        let defaults = UserDefaults(suiteName: "group.setInc.app.shared")

        guard let payload = defaults?.dictionary(forKey: "LA_Payload") as? [String: String] else {
            ExpoLiveActivityModule.logMessage("LA_Payload not found or invalid in App Group")
            return
        }


        let activityId = payload["activityId"] ?? ""
        let stopwatchId = payload["stopwatchId"] ?? ""
        let timerId = payload["timerId"] ?? ""
        let action = payload["action"] ?? ""
        let mode = payload["mode"] ?? ""
        ExpoLiveActivityModule.logMessage(
                """
                Parsed payload:
                activityId=\(activityId)
                stopwatchId=\(stopwatchId)
                timerId=\(timerId)
                action=\(action)
                mode=\(mode)
                """)
        sendEvent(
            "onButtonPressed",
            [
                "activityID": activityId,
                "stopwatchId": stopwatchId,
                "activityAction": action,
                "timerId": timerId,
                "mode": mode,
            ]
        )
        ExpoLiveActivityModule.logMessage("Event `onButtonPressed` sent to JS")
        // Clean up
        defaults?.removeObject(forKey: "LA_Payload")
        ExpoLiveActivityModule.logMessage("LA_Payload removed from App Group")
    }

    public static var shared: ExpoLiveActivityModule?

    public func definition() -> ModuleDefinition {
        Name("ExpoLiveActivity")

        OnCreate {
            if pushNotificationsEnabled {
                observePushToStartToken()
            }
            observeLiveActivityUpdates()
            ExpoLiveActivityModule.shared = self
            observeDarwinNotifications()
        }

        Events(
            "onTokenReceived",
            "onPushToStartTokenReceived",
            "onStateChange",
            "onButtonPressed"
        )

        Function("startActivity") {
            (state: LiveActivityState, maybeConfig: LiveActivityConfig?)
                -> String in
            guard #available(iOS 16.2, *) else {
                throw UnsupportedOSException("16.2")
            }

            guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                throw LiveActivitiesNotEnabledException()
            }

            do {
                let config = maybeConfig ?? LiveActivityConfig()

                let attributes = LiveActivityAttributes(
                    name: "ExpoLiveActivity",
                    backgroundColor: config.backgroundColor,
                    titleColor: config.titleColor,
                    subtitleColor: config.subtitleColor,
                    progressViewTint: config.progressViewTint,
                    progressViewLabelColor: config.progressViewLabelColor,
                    deepLinkUrl: config.deepLinkUrl,
                    timerType: config.timerType == .digital
                        ? .digital : .circular,
                    padding: config.padding,
                    paddingDetails: config.paddingDetails.map {
                        LiveActivityAttributes.PaddingDetails(
                            top: $0.top,
                            bottom: $0.bottom,
                            left: $0.left,
                            right: $0.right,
                            vertical: $0.vertical,
                            horizontal: $0.horizontal
                        )
                    },
                    imagePosition: config.imagePosition,
                    imageWidth: config.imageWidth,
                    imageHeight: config.imageHeight,
                    imageWidthPercent: config.imageWidthPercent,
                    imageHeightPercent: config.imageHeightPercent,
                    imageAlign: config.imageAlign,
                    contentFit: config.contentFit,
                    apiEndpoint: LiveActivityAttributes.ApiEndpoint(from: config.apiEndpoint),
                    accessToken: config.accessToken
                )

                let initialState = LiveActivityAttributes.ContentState(
                    title: state.title,
                    subtitle: state.subtitle,
                    mode: state.mode,
                    stopwatch: LiveActivityAttributes.Stopwatch(
                        id: state.stopwatch?.id ?? "",
                        startedAt: state.stopwatch?.startedAt,
                        accumulated: state.stopwatch?.accumulated ?? 0,
                        isRunning: state.stopwatch?.isRunning ?? false,
                        lapCount: state.stopwatch?.lapCount ?? 0
                        
                    ),
                    timer: LiveActivityAttributes.Timer(
                        id: state.timer?.id,
                        duration: state.timer?.duration,
                        remaining: state.timer?.remaining,
                        isRunning: state.timer?.isRunning ?? false,
                        endsAt: state.timer?.endsAt,
                        startTime: state.timer?.startTime
                    ),
                    showInDynamicIsland: state.showInDynamicIsland ?? false
                )

                let activity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: initialState, staleDate: nil)
                    
                )

                Task {
                    var newState = activity.content.state
                    await activity.update(
                        ActivityContent(state: newState, staleDate: nil)
                    )
                }

                return activity.id
            } catch {
                throw UnexpectedErrorException(error)
            }
        }

        Function("stopActivity") {
            (activityId: String, state: LiveActivityState) in
            guard #available(iOS 16.2, *) else {
                throw UnsupportedOSException("16.2")
            }

            guard
                let activity = Activity<LiveActivityAttributes>.activities
                    .first(where: {
                        $0.id == activityId
                    })
            else { throw ActivityNotFoundException(activityId) }

            Task {
                let newState = LiveActivityAttributes.ContentState(
                    title: state.title,
                    subtitle: state.subtitle,
                    mode: state.mode,
                    stopwatch: LiveActivityAttributes.Stopwatch(
                        id: state.stopwatch?.id ?? "",
                        startedAt: state.stopwatch?.startedAt,
                        accumulated: state.stopwatch?.accumulated ?? 0,
                        isRunning: state.stopwatch?.isRunning ?? false,
                        lapCount: state.stopwatch?.lapCount ?? 0
                    ),
                    timer: LiveActivityAttributes.Timer(
                        id: state.timer?.id,
                        duration: state.timer?.duration,
                        remaining: state.timer?.remaining,
                        isRunning: state.timer?.isRunning ?? false,
                        endsAt: state.timer?.endsAt,
                        startTime: state.timer?.startTime
                    ),
                    showInDynamicIsland: state.showInDynamicIsland ?? false
                )
                await activity.end(
                    ActivityContent(state: newState, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            }
        }

        Function("updateActivity") {
            (activityId: String, state: LiveActivityState) in
            guard #available(iOS 16.2, *) else {
                throw UnsupportedOSException("16.2")
            }

            guard
                let activity = Activity<LiveActivityAttributes>.activities
                    .first(where: {
                        $0.id == activityId
                    })
            else { throw ActivityNotFoundException(activityId) }

            Task {
                print(
                    "Updating activity with id: \(state.stopwatch?.id ?? "nil")"
                )
                let newState = LiveActivityAttributes.ContentState(
                    title: state.title,
                    subtitle: state.subtitle,
                    mode: state.mode,
                    stopwatch: LiveActivityAttributes.Stopwatch(
                        id: state.stopwatch?.id ?? "",
                        startedAt: state.stopwatch?.startedAt,
                        accumulated: state.stopwatch?.accumulated ?? 0,
                        isRunning: state.stopwatch?.isRunning ?? false,
                        lapCount: state.stopwatch?.lapCount ?? 0
                    ),
                    timer: LiveActivityAttributes.Timer(
                        id: state.timer?.id,
                        duration: state.timer?.duration,
                        remaining: state.timer?.remaining,
                        isRunning: state.timer?.isRunning ?? false,
                        endsAt: state.timer?.endsAt,
                        startTime: state.timer?.startTime
                    ),
                    showInDynamicIsland: state.showInDynamicIsland ?? false
                )
                await activity.update(
                    ActivityContent(state: newState, staleDate: nil)
                )
            }
        }
    }
}

extension LiveActivityAttributes.ApiEndpoint {
    init(from configApi: ExpoLiveActivityModule.LiveActivityConfig.ApiEndpoint?) {
        self.stopwatchEndpoints = configApi?.stopwatchEndpoints.map { endpoints in
            LiveActivityAttributes.StopwatchEndpoints(
                common: endpoints.common,
                lap: endpoints.lap
            )
        }
    }
}

extension LiveActivityAttributes.StopwatchEndpoints {
    init(from configEndpoints: ExpoLiveActivityModule.LiveActivityConfig.StopwatchEndpoints) {
        self.common = configEndpoints.common
        self.lap = configEndpoints.lap
    }
}

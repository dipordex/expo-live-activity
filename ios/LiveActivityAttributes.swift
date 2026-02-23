import ActivityKit
import Foundation

struct LiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var title: String?
        var subtitle: String?
        var mode: String?
        var stopwatch: Stopwatch?
        var timer: Timer?
        var task: Task?
        var showInDynamicIsland: Bool?
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
        
        init(id: String, startedAt: Date? = nil, accumulated: TimeInterval = 0, isRunning: Bool, lapCount: Int = 0) {
            self.id = id
            self.startedAt = startedAt
            self.accumulated = accumulated
            self.isRunning = isRunning
            self.lapCount = lapCount
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
    
    struct Task: Codable, Hashable {
        var id: String?
        var startDate: Date?
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

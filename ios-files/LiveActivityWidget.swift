import ActivityKit
import SwiftUI
import WidgetKit

struct LiveActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var title: String
    var subtitle: String?
    var mode: String?
    var stopwatch: Stopwatch?
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
    var id: String?
    var elapsed: String?
    var isRunning: Bool?
  }
}

struct LiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivityAttributes.self) { context in
      StopwatchLiveActivityView(
        title: context.state.title,
        stopwatch: context.state.stopwatch
      ).activityBackgroundTint(
        context.attributes.backgroundColor.map { Color(hex: $0) }
      )
      .activitySystemActionForegroundColor(Color.black)
      .applyWidgetURL(from: context.attributes.deepLinkUrl)

    } dynamicIsland: { context in
      let isRunning = context.state.stopwatch?.isRunning ?? false
      let elapsed = context.state.stopwatch?.elapsed ?? "00:00"
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          StopwatchExpandedLeadingView(
            title: context.state.title,
            subtitle: context.state.subtitle
          )
        }
        DynamicIslandExpandedRegion(.trailing) {
          StopwatchExpandedTrailingView(
            isRunning: isRunning
          )
        }

        DynamicIslandExpandedRegion(.bottom) {
          StopwatchExpandedBottomView(elapsed: elapsed)
        }

      } compactLeading: {
        StopwatchCompactLeadingView(elapsed: elapsed)

      } compactTrailing: {
        StopwatchCompactTrailingView(isRunning: isRunning)

      } minimal: {
        StopwatchMinimalView(isRunning: isRunning)
      }
    }
  }

  @ViewBuilder
  private func compactTimer(
    endDate: Double,
    timerType: LiveActivityAttributes.DynamicIslandTimerType,
    progressViewTint: String?
  ) -> some View {
    if timerType == .digital {
      Text(timerInterval: Date.toTimerInterval(miliseconds: endDate))
        .font(.system(size: 15))
        .minimumScaleFactor(0.8)
        .fontWeight(.semibold)
        .frame(maxWidth: 60)
        .multilineTextAlignment(.trailing)
    } else {
      circularTimer(endDate: endDate)
        .tint(progressViewTint.map { Color(hex: $0) })
    }
  }

  private func dynamicIslandExpandedLeading(title: String, subtitle: String?) -> some View {
    VStack(alignment: .leading) {
      Spacer()
      Text(title)
        .font(.title2)
        .foregroundStyle(.white)
        .fontWeight(.semibold)
      if let subtitle {
        Text(subtitle)
          .font(.title3)
          .minimumScaleFactor(0.8)
          .foregroundStyle(.white.opacity(0.75))
      }
      Spacer()
    }
  }

  private func dynamicIslandExpandedTrailing(imageName: String) -> some View {
    VStack {
      Spacer()
      resizableImage(imageName: imageName)
      Spacer()
    }
  }

  private func dynamicIslandExpandedBottom(endDate: Double, progressViewTint: String?) -> some View {
    ProgressView(timerInterval: Date.toTimerInterval(miliseconds: endDate))
      .foregroundStyle(.white)
      .tint(progressViewTint.map { Color(hex: $0) })
      .padding(.top, 5)
  }

  private func circularTimer(endDate: Double) -> some View {
    ProgressView(
      timerInterval: Date.toTimerInterval(miliseconds: endDate),
      countsDown: false,
      label: { EmptyView() },
      currentValueLabel: {
        EmptyView()
      }
    )
    .progressViewStyle(.circular)
  }
}

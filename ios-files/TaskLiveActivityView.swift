//
//  TaskLiveActivityView.swift
//  SetInc
//
//  Created by New MacMini2024 on 19/02/26.
//

import SwiftUI

struct TaskLiveActivityView: View {
  let title: String
  let subtitle: String?
  let activityId: String
  let task: LiveActivityAttributes.Task?

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .center, spacing: 10) {
        ZStack {
          Circle()
            .fill(.white.opacity(0.15))
            .frame(width: 34, height: 34)
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white)
        }
        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .lineLimit(1)

          if let subtitle = subtitle, !subtitle.isEmpty {
            Text(subtitle)
              .font(.system(size: 12, weight: .regular))
              .foregroundStyle(.white.opacity(0.6))
              .lineLimit(1)
          }
        }
        Spacer()
        // Status pill
        HStack(spacing: 5) {
          Circle()
            .fill(.green)
            .frame(width: 6, height: 6)
          Text("Active")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white.opacity(0.75))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.white.opacity(0.1))
        .clipShape(Capsule())
      }
      Divider()
        .background(.white.opacity(0.12))
        .padding(.vertical, 14)

      HStack(alignment: .center, spacing: 16) {
        VStack(alignment: .leading, spacing: 2) {
          Text("Elapsed")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white.opacity(0.5))
            .textCase(.uppercase)
            .kerning(0.5)

          if let startDate = task?.startDate {
            Text(startDate, style: .timer)
              .font(.system(size: 34, weight: .bold, design: .rounded))
              .monospacedDigit()
              .foregroundStyle(.white)
          } else {
            Text("--:--")
              .font(.system(size: 34, weight: .bold, design: .rounded))
              .foregroundStyle(.white.opacity(0.3))
          }
        }

        Spacer()

        CircleButton(
          symbol: "stop.fill",
          intent: StopTaskIntent(activityId: activityId, taskId: task?.id ?? "")
        )
      }
    }
    .padding(18)
  }
}

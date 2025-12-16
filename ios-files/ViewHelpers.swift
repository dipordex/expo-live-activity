import SwiftUI

func resizableImage(imageName: String) -> some View {
  Image.dynamic(assetNameOrPath: imageName)
    .resizable()
    .scaledToFit()
}

func resizableImage(imageName: String, height: CGFloat?, width: CGFloat?) -> some View {
  resizableImage(imageName: imageName)
    .frame(width: width, height: height)
}

private struct ContainerSizeKey: PreferenceKey {
  static var defaultValue: CGSize?
  static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
    value = nextValue() ?? value
  }
}

extension View {
  func captureContainerSize() -> some View {
    background(
      GeometryReader { proxy in
        Color.clear.preference(key: ContainerSizeKey.self, value: proxy.size)
      }
    )
  }

  func onContainerSize(_ perform: @escaping (CGSize?) -> Void) -> some View {
    onPreferenceChange(ContainerSizeKey.self, perform: perform)
  }
}

//MARK: Helpers Functions

func formatTime(_ seconds: TimeInterval) -> String {
  let total = max(0, Int(seconds))
  let h = total / 3600
  let m = (total % 3600) / 60
  let s = total % 60
  return h > 0
    ? String(format: "%02d:%02d:%02d", h, m, s)
    : String(format: "%02d:%02d", m, s)
}

func runningStartDate(_ sw: LiveActivityAttributes.Stopwatch) -> Date
{
  guard let startedAt = sw.startedAt else {
    return Date()
  }
  return startedAt.addingTimeInterval(-sw.accumulated)
}

extension Date {
  static func fromISO8601(_ value: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [
      .withInternetDateTime,
      .withFractionalSeconds
    ]
    return formatter.date(from: value)
  }
}

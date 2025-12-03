//
//  CircleButton.swift
//  SetInc
//
//  Created by New MacMini2024 on 03/12/25.
//
import SwiftUI
import AppIntents

struct CircleButton: View {
  let symbol: String
  let intent: AppIntent?
  let deepLink: String?
  
  init(symbol: String, intent: AppIntent? = nil, deepLink: String? = nil) {
    self.symbol = symbol
    self.intent = intent
    self.deepLink = deepLink
  }

  var body: some View {
    if #available(iOS 17.0, *), let intent = intent {
      // iOS 17 interactive button
      Button(intent: intent) {
        Image(systemName: symbol)
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(.white)
          .frame(width: 38, height: 38)
          .background(Color.gray.opacity(0.3))
          .clipShape(Circle())
      }
      .buttonStyle(.plain)

    } else {
      // Fallback: non-interactive icon OR deep link
      Image(systemName: symbol)
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(.white)
        .frame(width: 44, height: 44)
        .background(Color.gray.opacity(0.3))
        .clipShape(Circle())
        .widgetURL(deepLink.flatMap { URL(string: $0) })
    }
  }
}

struct PausedTag: View {
  var body: some View {
    Text("PAUSED")
      .font(.caption2.bold())
      .padding(.horizontal, 6)
      .padding(.vertical, 3)
      .foregroundStyle(.red)
      .background(Color.gray.opacity(0.5))
      .clipShape(Capsule())
  }
}

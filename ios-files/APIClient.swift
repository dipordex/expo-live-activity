//
//  APIClient.swift
//  SetInc
//
//  Created by New MacMini2024 on 16/12/25.
//

import Foundation

enum APIError: LocalizedError {
  case invalidURL
  case requestFailed(Error)
  case invalidResponse
  case serverError(statusCode: Int, data: Data?)
  case decodingFailed(Error)

  // Custom / App-defined error
  case custom(
    code: String,
    message: String,
    underlying: Error? = nil
  )

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid URL"

    case .requestFailed(let error):
      return "Request failed: \(error.localizedDescription)"

    case .invalidResponse:
      return "Invalid server response"

    case .serverError(let statusCode, _):
      return "Server error with status code \(statusCode)"

    case .decodingFailed(let error):
      return "Decoding failed: \(error.localizedDescription)"

    case .custom(_, let message, let underlying):
      if let underlying {
        return "\(message) (\(underlying.localizedDescription))"
      }
      return message
    }
  }
}

enum HTTPMethod: String {
  case GET, POST, PUT, DELETE, PATCH
}

struct APIRequest {
  let url: String
  let method: HTTPMethod
  let headers: [String: String]
  let body: Data?

  init(url: String,method: HTTPMethod = .GET,headers: [String: String] = [:],body: Data? = nil) {
    self.url = url
    self.method = method
    self.headers = headers
    self.body = body
  }
}

final class APIClient {
  static let shared = APIClient()
  private init() {}
  func request<T>(_ apiRequest: APIRequest,responseType: T.Type,shouldDecode: Bool = true)async throws -> T {
    guard let url = URL(string: apiRequest.url) else {
      throw APIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = apiRequest.method.rawValue
    request.httpBody = apiRequest.body
    request.timeoutInterval = 30

    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    apiRequest.headers.forEach {
      request.setValue($0.value, forHTTPHeaderField: $0.key)
    }
    let (data, response): (Data, URLResponse)
    do {
      (data, response) = try await URLSession.shared.data(for: request)
    } catch {
      throw APIError.requestFailed(error)
    }
    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIError.invalidResponse
    }
    guard (200...299).contains(httpResponse.statusCode) else {
      throw APIError.serverError(
        statusCode: httpResponse.statusCode,
        data: data
      )
    }
    // If no decoding needed (e.g. Void response)
    if !shouldDecode {
      return () as! T
    }
    do {
      if let decodableType = T.self as? Decodable.Type {
        return try JSONDecoder().decode(decodableType,from: data) as! T
      }
      return () as! T
    } catch {
      throw APIError.decodingFailed(error)
    }
  }
}


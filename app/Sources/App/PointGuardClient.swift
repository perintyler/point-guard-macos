import Foundation
import PointGuardCore

/// Talks to point-guard's own HTTP API directly -- deliberately NOT through
/// `BarryCore`.
///
/// BarryKit is still declared as a Package.swift dependency here (for
/// consistency with the other bag apps, and so the product-line table in
/// BarryKit's README can eventually list this one), but `BarryCore`'s
/// launchd-plist discovery resolves the port/secret for Barry's MAIN API
/// server (`com.barry.api`, default port 4854) -- a completely different
/// service on a different port. Reusing that discovery here would silently
/// point this app at the wrong service whenever the two ever drift, so this
/// client does its own minimal env-var-based discovery instead, matching the
/// pattern point-guard's own Rust TUI client already establishes in
/// `bags/point-guard/tui/src/net.rs`'s `Service::from_env()`:
/// - `BARRY_POINT_GUARD_URL` overrides the full base URL (dev/testing).
/// - Otherwise the base URL defaults to `http://127.0.0.1:3868`, point-guard's
///   fixed port (overridable server-side via `BARRY_POINT_GUARD_PORT`, but
///   this client only needs to AGREE with whatever the service is bound to,
///   which the URL override covers for the dev case).
/// - `BARRY_SECRET` is read directly from the process environment, the same
///   secret point-guard's Express middleware checks against `Authorization:
///   Bearer <secret>` -- there is no separate point-guard secret.
public actor PointGuardClient {
    private let baseURL: URL
    private let secret: String?
    private let session: URLSession

    public init() {
        let environment = ProcessInfo.processInfo.environment
        if let raw = environment["BARRY_POINT_GUARD_URL"], let url = URL(string: raw) {
            self.baseURL = url
        } else {
            self.baseURL = URL(string: "http://127.0.0.1:3868")!
        }
        self.secret = environment["BARRY_SECRET"]

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
    }

    public func fetchBook() async throws -> BookResponse {
        try await get("book")
    }

    public func fetchMessageHistory(limit: Int = 50) async throws -> MessageHistoryResponse {
        try await get("message/history", query: [URLQueryItem(name: "limit", value: String(limit))])
    }

    public func sendMessage(content: String) async throws -> MessageSendResult {
        var request = URLRequest(url: baseURL.appendingPathComponent("message"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuth(&request)
        request.httpBody = try JSONEncoder().encode(["content": content])

        let (data, response) = try await session.data(for: request)
        try validate(data: data, response: response)
        return try JSONDecoder().decode(MessageSendResult.self, from: data)
    }

    private func get<T: Decodable>(_ path: String, query: [URLQueryItem]? = nil) async throws -> T {
        var url = baseURL.appendingPathComponent(path)
        if let query, !query.isEmpty, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.queryItems = query
            if let composed = components.url {
                url = composed
            }
        }

        var request = URLRequest(url: url)
        addAuth(&request)
        let (data, response) = try await session.data(for: request)
        try validate(data: data, response: response)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func addAuth(_ request: inout URLRequest) {
        if let secret {
            request.setValue("Bearer " + secret, forHTTPHeaderField: "Authorization")
        }
    }

    private func validate(data: Data, response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let body = try? JSONDecoder().decode(PointGuardErrorBody.self, from: data)
            throw PointGuardClientError.serverError(body?.error ?? "Request failed")
        }
    }
}

/// `{"error": string}`, the shape every point-guard endpoint returns on a
/// non-2xx response.
private struct PointGuardErrorBody: Decodable {
    let error: String
}

public enum PointGuardClientError: LocalizedError {
    case serverError(String)

    public var errorDescription: String? {
        switch self {
        case .serverError(let message): return message
        }
    }
}

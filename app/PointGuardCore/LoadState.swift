import Foundation

/// The state of a fetch. `loaded([])` and `failed` are separate cases so a
/// broken connection can never render as a quiet, honest empty list -- the
/// same distinction `LoadState` draws in ActionsFeature/BarrySessionsCore.
public enum LoadState<Value: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value)
    case failed(String)

    public var value: Value? {
        if case let .loaded(value) = self { return value }
        return nil
    }

    public var errorMessage: String? {
        if case let .failed(message) = self { return message }
        return nil
    }

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

/// Turns a thrown error into something a person can act on.
public func describePointGuardFailure(_ error: Error) -> String {
    if let urlError = error as? URLError {
        switch urlError.code {
        case .cannotConnectToHost, .cannotFindHost, .networkConnectionLost:
            return "Cannot reach point-guard. Is the point-guard service running on port 3868?"
        case .timedOut:
            return "point-guard did not respond in time."
        default:
            return "Request failed: " + urlError.localizedDescription
        }
    }
    return "Request failed: " + error.localizedDescription
}

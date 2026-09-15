import Foundation

/// Turns a repo path into a short, readable name for the row list.
public enum RepoName {
    /// The real data points `repo` at the `.git` directory itself, not the
    /// repo's working root (e.g. `/Users/tyler/repos/barry/.git`) -- so a plain
    /// last-path-component would show ".git" instead of "barry". Strip a
    /// trailing `.git` component first, then take what's left.
    ///
    /// `nil` input (no git repo for this session) returns `nil` -- callers
    /// render that as absent, not as an error or a placeholder string.
    public static func displayName(repo: String?) -> String? {
        guard let repo, !repo.isEmpty else { return nil }

        var path = repo
        if path.hasSuffix("/") {
            path.removeLast()
        }
        if (path as NSString).lastPathComponent == ".git" {
            path = (path as NSString).deletingLastPathComponent
        }

        let name = (path as NSString).lastPathComponent
        return name.isEmpty ? nil : name
    }
}

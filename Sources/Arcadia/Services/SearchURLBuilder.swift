import Foundation

/// Turns explorer start-page input into a URL: the typed address or a Google
/// search. Google is the default (and only) search engine.
enum SearchURLBuilder {
    static func url(from input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if looksLikeURL(trimmed) {
            if trimmed.contains("://") {
                return URL(string: trimmed)
            }
            return URL(string: "https://\(trimmed)")
        }
        return googleSearch(for: trimmed)
    }

    static func googleSearch(for query: String) -> URL? {
        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        return components?.url
    }

    private static func looksLikeURL(_ s: String) -> Bool {
        if s.contains("://") { return true }
        if s.contains(" ") { return false }
        guard let dot = s.firstIndex(of: ".") else { return false }
        return dot < s.index(before: s.endIndex)
    }
}

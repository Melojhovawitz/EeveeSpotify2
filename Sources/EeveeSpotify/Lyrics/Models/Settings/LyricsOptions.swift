import Foundation

struct LyricsOptions: Codable, Hashable {
    var romanization: Bool
    var musixmatchLanguage: String
    var lrclibUrl: String
    var geniusFallback: Bool
    var showFallbackReasons: Bool
    var hideOnError: Bool
    
    // Spicy Lyrics specific options
    var spicyShowConfidenceScores: Bool
    var spicyHighlightEmphasis: Bool
    var spicyShowTransliteration: Bool
    var spicyCacheEnabled: Bool
    var spicyApiUrl: String
}

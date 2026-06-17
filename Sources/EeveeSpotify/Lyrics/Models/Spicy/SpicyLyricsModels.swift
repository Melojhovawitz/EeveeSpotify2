import Foundation

struct SpicySearchResponse: Codable {
    let results: [SpicyTrackResult]
    let total: Int
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case results
        case total
        case hasMore = "has_more"
    }
}

struct SpicyTrackResult: Codable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let duration: Int
    let popularity: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artist
        case album
        case duration
        case popularity
    }
}

struct SpicyLyricsResponse: Codable {
    let trackId: String
    let lines: [SpicyLyricsLine]
    let isTimeSynced: Bool
    let metadata: SpicyMetadata
    let quality: SpicyLyricsQuality
    
    enum CodingKeys: String, CodingKey {
        case trackId = "track_id"
        case lines
        case isTimeSynced = "is_time_synced"
        case metadata
        case quality
    }
}

struct SpicyLyricsLine: Codable {
    let text: String
    let startTime: Int?
    let endTime: Int?
    let confidence: Double?
    let emphasis: [Int]?  // Indices of emphasized words
    let transliteration: String?
    
    enum CodingKeys: String, CodingKey {
        case text
        case startTime = "start_time"
        case endTime = "end_time"
        case confidence
        case emphasis
        case transliteration
    }
}

struct SpicyMetadata: Codable {
    let source: String
    let version: String
    let timestamp: String
    let language: String
    let hasExplicit: Bool
    
    enum CodingKeys: String, CodingKey {
        case source
        case version
        case timestamp
        case language
        case hasExplicit = "has_explicit"
    }
}

enum SpicyLyricsQuality: String, Codable {
    case poor
    case fair
    case good
    case excellent
}

struct SpicyLyricsCache: Codable {
    let trackId: String
    let lyrics: SpicyLyricsResponse
    let cachedAt: Date
    
    var isExpired: Bool {
        // Cache expires after 7 days
        let expirationInterval: TimeInterval = 7 * 24 * 60 * 60
        return Date().timeIntervalSince(cachedAt) > expirationInterval
    }
}

struct SpicyLyricsError: Codable {
    let error: String
    let code: String
    let message: String?
    let retryAfter: Int?
    
    enum CodingKeys: String, CodingKey {
        case error
        case code
        case message
        case retryAfter = "retry_after"
    }
}

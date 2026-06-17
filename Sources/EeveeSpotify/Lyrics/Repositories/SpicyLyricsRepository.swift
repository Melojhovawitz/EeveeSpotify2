import Foundation

class SpicyLyricsRepository: LyricsRepository {
    private let session: URLSession
    private let apiUrl: String
    private var cache: [String: SpicyLyricsCache] = [:]
    private let cacheQueue = DispatchQueue(label: "com.eevee.spicy.cache", attributes: .concurrent)
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    
    private static let defaultApiUrl = "https://api.spicy-lyrics.app"
    private static let timeoutInterval: TimeInterval = 15
    private static let retryAttempts = 3
    private static let retryDelay: TimeInterval = 1.0
    
    init(apiUrl: String? = nil) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Self.timeoutInterval
        configuration.timeoutIntervalForResource = Self.timeoutInterval * 2
        configuration.waitsForConnectivity = true
        configuration.httpAdditionalHeaders = [
            "User-Agent": "EeveeSpotify/1.0",
            "X-Client-Version": "1.0.0"
        ]
        
        session = URLSession(configuration: configuration)
        self.apiUrl = apiUrl ?? Self.defaultApiUrl
        
        jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        
        jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Public API
    
    func getLyrics(_ query: LyricsSearchQuery, options: LyricsOptions) throws -> LyricsDto {
        // 1. Check cache first
        if options.spicyCacheEnabled, let cachedLyrics = getCachedLyrics(for: query.spotifyTrackId) {
            NSLog("[SpicyLyrics] Returning cached lyrics for track: \(query.spotifyTrackId)")
            return convertToLyricsDto(cachedLyrics.lyrics, options: options)
        }
        
        // 2. Search for track
        let searchResults = try searchTrack(
            title: query.title,
            artist: query.primaryArtist
        )
        
        guard let trackId = searchResults.first?.id else {
            throw LyricsError.noSuchSong
        }
        
        // 3. Fetch lyrics with retry logic
        var lastError: Error?
        for attempt in 1...Self.retryAttempts {
            do {
                let lyricsResponse = try fetchSpicyLyrics(trackId: trackId)
                
                // Cache the result
                if options.spicyCacheEnabled {
                    cacheSpicyLyrics(lyricsResponse, for: query.spotifyTrackId)
                }
                
                return convertToLyricsDto(lyricsResponse, options: options)
            } catch let error as URLError where error.code == .timedOut {
                lastError = LyricsError.spicyTimeout
                if attempt < Self.retryAttempts {
                    let delay = Self.retryDelay * Double(attempt)
                    Thread.sleep(forTimeInterval: delay)
                }
            } catch let error as URLError where error.code == .networkConnectionLost {
                lastError = LyricsError.spicyNetworkError
                if attempt < Self.retryAttempts {
                    let delay = Self.retryDelay * Double(attempt)
                    Thread.sleep(forTimeInterval: delay)
                }
            } catch {
                lastError = error
                break
            }
        }
        
        throw lastError ?? LyricsError.unknownError
    }
    
    // MARK: - Private Methods
    
    private func searchTrack(title: String, artist: String) throws -> [SpicyTrackResult] {
        let query = "\(title) \(artist)"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let urlString = "\(apiUrl)/v1/search?q=\(encodedQuery)&type=track&limit=1"
        guard let url = URL(string: urlString) else {
            throw LyricsError.spicyInvalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try performRequest(request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LyricsError.spicyNetworkError
        }
        
        switch httpResponse.statusCode {
        case 200:
            break
        case 429:
            throw LyricsError.spicyRateLimited
        case 400...499:
            throw LyricsError.spicyInvalidResponse
        case 500...599:
            throw LyricsError.spicyNetworkError
        default:
            throw LyricsError.unknownError
        }
        
        do {
            let response = try jsonDecoder.decode(SpicySearchResponse.self, from: data)
            return response.results
        } catch {
            NSLog("[SpicyLyrics] Failed to decode search response: \(error)")
            throw LyricsError.decodingError
        }
    }
    
    private func fetchSpicyLyrics(trackId: String) throws -> SpicyLyricsResponse {
        let urlString = "\(apiUrl)/v1/lyrics/\(trackId)"
        guard let url = URL(string: urlString) else {
            throw LyricsError.spicyInvalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try performRequest(request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LyricsError.spicyNetworkError
        }
        
        switch httpResponse.statusCode {
        case 200:
            break
        case 404:
            throw LyricsError.noSuchSong
        case 429:
            throw LyricsError.spicyRateLimited
        case 400...499:
            throw LyricsError.spicyInvalidResponse
        case 500...599:
            throw LyricsError.spicyNetworkError
        default:
            throw LyricsError.unknownError
        }
        
        do {
            let lyricsResponse = try jsonDecoder.decode(SpicyLyricsResponse.self, from: data)
            NSLog("[SpicyLyrics] Successfully fetched lyrics for track: \(trackId), quality: \(lyricsResponse.quality), lines: \(lyricsResponse.lines.count)")
            return lyricsResponse
        } catch {
            NSLog("[SpicyLyrics] Failed to decode lyrics response: \(error)")
            throw LyricsError.decodingError
        }
    }
    
    private func performRequest(_ request: URLRequest) throws -> (Data, URLResponse) {
        let semaphore = DispatchSemaphore(value: 0)
        var responseData: Data?
        var urlResponse: URLResponse?
        var error: Error?
        
        let task = session.dataTask(with: request) { data, response, err in
            responseData = data
            urlResponse = response
            error = err
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        
        if let error = error {
            throw error
        }
        
        guard let data = responseData, let response = urlResponse else {
            throw LyricsError.spicyNetworkError
        }
        
        return (data, response)
    }
    
    private func convertToLyricsDto(_ response: SpicyLyricsResponse, options: LyricsOptions) -> LyricsDto {
        var lines: [LyricsLineDto] = []
        
        for line in response.lines {
            var lineContent = line.text
            
            // Add confidence score display if enabled
            if options.spicyShowConfidenceScores, let confidence = line.confidence {
                let confidencePercent = Int(confidence * 100)
                lineContent = "\(lineContent) [\(confidencePercent)%]"
            }
            
            // Add transliteration if available and enabled
            if options.spicyShowTransliteration, let transliteration = line.transliteration {
                lineContent = "\(lineContent)\n(\(transliteration))"
            }
            
            // Highlight emphasized words if enabled
            if options.spicyHighlightEmphasis, let emphasisIndices = line.emphasis, !emphasisIndices.isEmpty {
                let words = lineContent.split(separator: " ")
                var highlightedWords: [String] = []
                
                for (index, word) in words.enumerated() {
                    if emphasisIndices.contains(index) {
                        highlightedWords.append("*\(word)*")
                    } else {
                        highlightedWords.append(String(word))
                    }
                }
                
                lineContent = highlightedWords.joined(separator: " ")
            }
            
            let lineDto = LyricsLineDto(
                content: lineContent,
                startTimeMs: line.startTime ?? 0
            )
            lines.append(lineDto)
        }
        
        return LyricsDto(
            lines: lines,
            timeSynced: response.isTimeSynced,
            romanization: .original
        )
    }
    
    // MARK: - Caching Methods
    
    private func getCachedLyrics(for trackId: String) -> SpicyLyricsCache? {
        var cachedLyrics: SpicyLyricsCache?
        
        cacheQueue.sync {
            if let cached = cache[trackId], !cached.isExpired {
                cachedLyrics = cached
            } else if cache[trackId] != nil {
                // Remove expired cache
                cache.removeValue(forKey: trackId)
            }
        }
        
        return cachedLyrics
    }
    
    private func cacheSpicyLyrics(_ lyrics: SpicyLyricsResponse, for trackId: String) {
        let cached = SpicyLyricsCache(
            trackId: trackId,
            lyrics: lyrics,
            cachedAt: Date()
        )
        
        cacheQueue.async(flags: .barrier) {
            self.cache[trackId] = cached
            NSLog("[SpicyLyrics] Cached lyrics for track: \(trackId)")
        }
    }
    
    func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.cache.removeAll()
            NSLog("[SpicyLyrics] Cache cleared")
        }
    }
}

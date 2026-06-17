import Orion
import SwiftUI

// Add Spicy Lyrics integration into CustomLyrics
var spicyLyricsRepository = SpicyLyricsRepository()

// Add to the switch statement in loadCustomLyricsForTrackId and loadCustomLyricsForCurrentTrack
// This extension adds Spicy Lyrics support

extension CustomLyrics {
    func setupSpicyLyricsIntegration() {
        NSLog("[EeveeSpotify] Spicy Lyrics integration initialized")
    }
}

// Hook into existing lyrics loading to include Spicy Lyrics
class SpicyLyricsIntegrationHook {
    static func integrateSpicyLyrics(into repository: inout LyricsRepository, source: LyricsSource) {
        if source == .spicy {
            repository = spicyLyricsRepository
            NSLog("[EeveeSpotify] Using Spicy Lyrics provider")
        }
    }
}

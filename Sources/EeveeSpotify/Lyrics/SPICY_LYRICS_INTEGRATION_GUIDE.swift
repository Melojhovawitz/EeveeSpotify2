import Foundation

// MARK: - Integration into CustomLyrics.x.swift
// Add the following to the switch statement in loadCustomLyricsForTrackId function:
// case .spicy:
//     repository = spicyLyricsRepository

// Example of how to integrate into the existing CustomLyrics.x.swift file:
/*
 private let spicyLyricsRepository = SpicyLyricsRepository()
 
 var repository: LyricsRepository
 
 switch source {
 case .genius:
     repository = geniusLyricsRepository
 case .lrclib:
     repository = LrclibLyricsRepository.shared
 case .musixmatch:
     repository = MusixmatchLyricsRepository.shared
 case .petit:
     repository = petitLyricsRepository
 case .spicy:
     repository = spicyLyricsRepository
 case .notReplaced:
     throw LyricsError.invalidSource
 }
 */

// MARK: - Custom Lyrics Integration Code
let spicyLyricsIntegration = """
// Add this code to Sources/EeveeSpotify/Lyrics/CustomLyrics.x.swift

// 1. Add at the top with other repositories:
private let spicyLyricsRepository = SpicyLyricsRepository()

// 2. In loadCustomLyricsForTrackId function, add to switch statement:
case .spicy:
    repository = spicyLyricsRepository

// 3. In loadCustomLyricsForCurrentTrack function, add to switch statement:
case .spicy:
    repository = spicyLyricsRepository

// 4. Ensure error handling includes Spicy specific errors:
case .spicyNetworkError:
    if !hasShownNetworkErrorPopUp {
        DispatchQueue.main.async {
            PopUpHelper.showPopUp(
                delayed: false,
                message: "spicy_network_error_popup".localized,
                buttonText: "OK".uiKitLocalized
            )
        }
        hasShownNetworkErrorPopUp = true
    }
case .spicyTimeout:
    if !hasShownTimeoutPopUp {
        DispatchQueue.main.async {
            PopUpHelper.showPopUp(
                delayed: false,
                message: "spicy_timeout_popup".localized,
                buttonText: "OK".uiKitLocalized
            )
        }
        hasShownTimeoutPopUp = true
    }
case .spicyRateLimited:
    if !hasShownRateLimitPopUp {
        DispatchQueue.main.async {
            PopUpHelper.showPopUp(
                delayed: false,
                message: "spicy_rate_limited_popup".localized,
                buttonText: "OK".uiKitLocalized
            )
        }
        hasShownRateLimitPopUp = true
    }
"""

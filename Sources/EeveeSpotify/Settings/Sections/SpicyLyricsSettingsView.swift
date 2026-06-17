import SwiftUI

struct SpicyLyricsSettingsView: View {
    @State private var showConfidenceScores = false
    @State private var highlightEmphasis = true
    @State private var showTransliteration = true
    @State private var cacheEnabled = true
    @State private var apiUrl = "https://api.spicy-lyrics.app"
    @State private var selectedQuality: String = "excellent"
    
    var body: some View {
        Form {
            Section(header: Text("Spicy Lyrics Options").font(.headline)) {
                Toggle("Show Confidence Scores", isOn: $showConfidenceScores)
                    .onChange(of: showConfidenceScores) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "spicy_show_confidence_scores")
                    }
                    .help("Display accuracy confidence percentage for each lyric line")
                
                Toggle("Highlight Emphasized Words", isOn: $highlightEmphasis)
                    .onChange(of: highlightEmphasis) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "spicy_highlight_emphasis")
                    }
                    .help("Highlight stressed or emphasized syllables in lyrics")
                
                Toggle("Show Transliteration", isOn: $showTransliteration)
                    .onChange(of: showTransliteration) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "spicy_show_transliteration")
                    }
                    .help("Display phonetic transcriptions for non-Latin scripts")
            }
            
            Section(header: Text("Cache Settings").font(.headline)) {
                Toggle("Enable Caching", isOn: $cacheEnabled)
                    .onChange(of: cacheEnabled) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "spicy_cache_enabled")
                    }
                    .help("Cache lyrics for 7 days to reduce API calls")
                
                if cacheEnabled {
                    Button(action: clearSpicyCache) {
                        Text("Clear Cache")
                            .foregroundColor(.red)
                    }
                    .help("Clear all cached Spicy Lyrics data")
                }
            }
            
            Section(header: Text("API Configuration").font(.headline)) {
                HStack {
                    Text("API URL")
                    TextField("API URL", text: $apiUrl)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .onChange(of: apiUrl) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "spicy_api_url")
                        }
                }
                
                Picker("Quality Level", selection: $selectedQuality) {
                    Text("Poor").tag("poor")
                    Text("Fair").tag("fair")
                    Text("Good").tag("good")
                    Text("Excellent").tag("excellent")
                }
                .onChange(of: selectedQuality) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "spicy_quality_level")
                }
                .help("Minimum quality threshold for accepting lyrics")
            }
            
            Section(header: Text("Information").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About Spicy Lyrics")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Spicy Lyrics provides enhanced lyrics with:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Confidence scores", systemImage: "checkmark.circle")
                        Label("Emphasis markers", systemImage: "checkmark.circle")
                        Label("Phonetic transcriptions", systemImage: "checkmark.circle")
                        Label("Time-synced lyrics", systemImage: "checkmark.circle")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("Spicy Lyrics")
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        showConfidenceScores = UserDefaults.standard.bool(forKey: "spicy_show_confidence_scores")
        highlightEmphasis = UserDefaults.standard.bool(forKey: "spicy_highlight_emphasis") || true
        showTransliteration = UserDefaults.standard.bool(forKey: "spicy_show_transliteration") || true
        cacheEnabled = UserDefaults.standard.bool(forKey: "spicy_cache_enabled") || true
        apiUrl = UserDefaults.standard.string(forKey: "spicy_api_url") ?? "https://api.spicy-lyrics.app"
        selectedQuality = UserDefaults.standard.string(forKey: "spicy_quality_level") ?? "excellent"
    }
    
    private func clearSpicyCache() {
        spicyLyricsRepository.clearCache()
        // Show confirmation
        DispatchQueue.main.async {
            NSLog("[EeveeSpotify] Spicy Lyrics cache cleared")
        }
    }
}

struct SpicyLyricsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SpicyLyricsSettingsView()
        }
    }
}

import SwiftUI

// This file integrates Spicy Lyrics into the main EeveeSpotify settings
extension View {
    func spicyLyricsSettings() -> some View {
        self
    }
}

struct LyricsSettingsSectionView: View {
    @State private var selectedLyricsSource: LyricsSource = .musixmatch
    @State private var showSpicySettings = false
    
    var body: some View {
        Form {
            Section(header: Text("Lyrics Provider").font(.headline)) {
                Picker("Lyrics Source", selection: $selectedLyricsSource) {
                    ForEach(LyricsSource.allCases, id: \.self) { source in
                        if source.isReplacingLyrics {
                            Text(source.description).tag(source)
                        }
                    }
                }
                .onChange(of: selectedLyricsSource) { newValue in
                    UserDefaults.standard.set(newValue.rawValue, forKey: "lyrics_source")
                    NSLog("[EeveeSpotify] Lyrics source changed to: \(newValue.description)")
                }
                .pickerStyle(.menu)
                
                if selectedLyricsSource == .spicy {
                    NavigationLink(destination: SpicyLyricsSettingsView()) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Spicy Lyrics Settings")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            
            Section(header: Text("General Options").font(.headline)) {
                NavigationLink(destination: GeneralLyricsSettingsView()) {
                    HStack {
                        Image(systemName: "gearshape")
                        Text("General Settings")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("Lyrics")
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        if let sourceRawValue = UserDefaults.standard.object(forKey: "lyrics_source") as? Int,
           let source = LyricsSource(rawValue: sourceRawValue) {
            selectedLyricsSource = source
        }
    }
}

struct GeneralLyricsSettingsView: View {
    @State private var geniusFallback = true
    @State private var hideOnError = false
    @State private var romanization = false
    
    var body: some View {
        Form {
            Section(header: Text("Fallback Options").font(.headline)) {
                Toggle("Enable Genius Fallback", isOn: $geniusFallback)
                    .onChange(of: geniusFallback) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "lyrics_genius_fallback")
                    }
                    .help("Use Genius as fallback if primary source fails")
            }
            
            Section(header: Text("Display Options").font(.headline)) {
                Toggle("Hide on Error", isOn: $hideOnError)
                    .onChange(of: hideOnError) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "lyrics_hide_on_error")
                    }
                    .help("Hide lyrics panel if loading fails")
                
                Toggle("Enable Romanization", isOn: $romanization)
                    .onChange(of: romanization) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "lyrics_romanization")
                    }
                    .help("Show romanized versions of non-Latin scripts")
            }
        }
        .navigationTitle("General Lyrics Settings")
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        geniusFallback = UserDefaults.standard.bool(forKey: "lyrics_genius_fallback") || true
        hideOnError = UserDefaults.standard.bool(forKey: "lyrics_hide_on_error")
        romanization = UserDefaults.standard.bool(forKey: "lyrics_romanization")
    }
}

struct LyricsSettingsSectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LyricsSettingsSectionView()
        }
    }
}

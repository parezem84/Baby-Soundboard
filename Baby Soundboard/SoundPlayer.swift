import AVFoundation
import SwiftUI
import MediaPlayer
import UIKit

class SoundPlayer: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    @Published var isPlaying = false
    @Published var currentSound: String?
    private var defaultVolume: Float = 0.2 // Default to 20%
    
    // Timer properties
    @Published var timerActive = false
    @Published var timeRemaining: TimeInterval = 0
    private var stopTimer: Timer?
    private var countdownTimer: Timer?
    private var audioStateMonitor: Timer?
    
    init() {
        NSLog("MOONNEST_LOG: SoundPlayer initialized - logging test")
        print("MOONNEST_LOG: SoundPlayer initialized - logging test")
        setupAudioSession()
        setupAudioSessionNotifications()
        setupRemoteCommandCenter()
        loadVolumeFromUserDefaults()
        setupBackgroundAudioMonitoring()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Configure for background audio playback with proper category and options
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Enable remote control events
            UIApplication.shared.beginReceivingRemoteControlEvents()
            
            print("Audio session configured for background playback")
            print("Audio session category: \(audioSession.category)")
            print("Audio session mode: \(audioSession.mode)")
            print("Audio session is active: \(audioSession.isOtherAudioPlaying)")
            print("Background modes enabled: \(Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") ?? "None")")
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Enable play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            if let self = self, let currentSound = self.currentSound {
                self.playSound(currentSound)
                return .success
            }
            return .commandFailed
        }
        
        // Enable pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.stopSound()
            return .success
        }
        
        // Enable stop command
        commandCenter.stopCommand.isEnabled = true
        commandCenter.stopCommand.addTarget { [weak self] _ in
            self?.stopSound()
            return .success
        }
        
        // Enable toggle play/pause command
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.isPlaying {
                self.stopSound()
            } else if let currentSound = self.currentSound {
                self.playSound(currentSound)
            }
            return .success
        }
    }
    
    private func updateNowPlayingInfo(soundName: String) {
        let soundDisplayName = getSoundDisplayName(soundName)
        
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: soundDisplayName,
            MPMediaItemPropertyArtist: "MoonNest",
            MPMediaItemPropertyAlbumTitle: "Sleep Sounds",
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPMediaItemPropertyPlaybackDuration: 0.0 // Infinite loop
        ]
        
        // Add artwork if available
        if let artwork = createArtworkForSound(soundName) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func createArtworkForSound(_ soundName: String) -> MPMediaItemArtwork? {
        // Create a simple colored artwork
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Use gradient background
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: [UIColor(red: 0.53, green: 0.81, blue: 0.92, alpha: 1.0).cgColor,
                                            UIColor(red: 0.29, green: 0.0, blue: 0.51, alpha: 1.0).cgColor] as CFArray,
                                    locations: [0.0, 1.0])
            
            context.cgContext.drawLinearGradient(gradient!,
                                               start: CGPoint(x: 0, y: 0),
                                               end: CGPoint(x: 0, y: size.height),
                                               options: [])
            
            // Add sound name
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            
            let displayName = getSoundDisplayName(soundName)
            let textSize = displayName.size(withAttributes: attributes)
            let textRect = CGRect(x: (size.width - textSize.width) / 2,
                                y: (size.height - textSize.height) / 2,
                                width: textSize.width,
                                height: textSize.height)
            
            displayName.draw(in: textRect, withAttributes: attributes)
        }
        
        return MPMediaItemArtwork(boundsSize: size) { _ in image }
    }
    
    private func getSoundDisplayName(_ soundName: String) -> String {
        let soundDict = [
            "rain": "Rain",
            "white_noise": "White Noise",
            "heartbeat": "Heartbeat",
            "ocean_waves": "Ocean Waves",
            "car_ride": "Car Ride",
            "washing_machine": "Washing Machine",
            "fireplace": "Fireplace",
            "wind": "Wind",
            "lullaby": "Lullaby",
            "birds_chirping": "Birds Chirping"
        ]
        return soundDict[soundName] ?? soundName
    }
    
    private func setupBackgroundAudioMonitoring() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("🎵 MOONNEST_LOG: App entered background - checking audio state")
            print("🎵 MOONNEST_LOG: Audio player exists: \(self.audioPlayer != nil)")
            print("🎵 MOONNEST_LOG: Audio player isPlaying: \(self.audioPlayer?.isPlaying ?? false)")
            print("🎵 MOONNEST_LOG: Published isPlaying: \(self.isPlaying)")
            
            // CRITICAL FIX: Reactivate audio session for background playback
            if self.isPlaying && self.audioPlayer != nil {
                do {
                    let session = AVAudioSession.sharedInstance()
                    print("🎵 MOONNEST_LOG: Reactivating audio session for background...")
                    
                    // Ensure background audio configuration
                    try session.setCategory(.playback, mode: .default, options: [])
                    try session.setActive(true, options: [.notifyOthersOnDeactivation])
                    
                    print("🎵 MOONNEST_LOG: Audio session reactivated successfully")
                    print("🎵 MOONNEST_LOG: Session category: \(session.category)")
                    print("🎵 MOONNEST_LOG: Session is now active: \(!session.isOtherAudioPlaying)")
                    
                    // Ensure audio player is still playing
                    if let player = self.audioPlayer, !player.isPlaying {
                        print("🎵 MOONNEST_LOG: Player stopped, restarting...")
                        player.play()
                    }
                    
                } catch {
                    print("🎵 MOONNEST_LOG: ❌ Failed to reactivate audio session: \(error)")
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("🎵 MOONNEST_LOG: App will enter foreground - checking audio state")
            print("🎵 MOONNEST_LOG: Audio player exists: \(self.audioPlayer != nil)")
            print("🎵 MOONNEST_LOG: Audio player isPlaying: \(self.audioPlayer?.isPlaying ?? false)")
            print("🎵 MOONNEST_LOG: Published isPlaying: \(self.isPlaying)")
        }
    }
    
    private func setupAudioSessionNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }
    
    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Audio session was interrupted (phone call, etc.)
            print("Audio session interrupted")
        case .ended:
            // Audio session interruption ended
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                
                // Check if we should resume playback
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) && isPlaying {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.audioPlayer?.play()
                        }
                    }
                }
            } catch {
                print("Error reactivating audio session: \(error)")
            }
        @unknown default:
            break
        }
    }
    
    @objc private func handleAudioSessionRouteChange(notification: Notification) {
        // Handle audio route changes (headphones plugged/unplugged, etc.)
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            // Headphones were unplugged, pause playback
            stopSound()
        default:
            break
        }
    }
    
    private func loadVolumeFromUserDefaults() {
        let savedVolume = UserDefaults.standard.double(forKey: "defaultVolume")
        if savedVolume == 0 && !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            // First launch, set default volume to 20
            UserDefaults.standard.set(20.0, forKey: "defaultVolume")
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            defaultVolume = 0.2
        } else {
            defaultVolume = Float(savedVolume / 100.0)
        }
    }
    
    func setVolume(_ volume: Double) {
        defaultVolume = Float(volume)
        audioPlayer?.volume = defaultVolume
    }
    
    func playSound(_ soundName: String) {
        NSLog("MOONNEST_LOG: playSound called for %@", soundName)
        print("MOONNEST_LOG: playSound called for \(soundName)")
        
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            print("🎵 MOONNEST_LOG: ERROR - Could not find sound file: \(soundName).mp3")
            return
        }
        
        print("🎵 MOONNEST_LOG: Sound file found at \(url)")
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            print("🎵 MOONNEST_LOG: Got audio session instance")
            
            // Check initial session state
            print("🎵 MOONNEST_LOG: Initial session category: \(audioSession.category)")
            print("🎵 MOONNEST_LOG: Initial session mode: \(audioSession.mode)")
            print("🎵 MOONNEST_LOG: Other audio playing: \(audioSession.isOtherAudioPlaying)")
            
            // Ensure audio session is configured and active for background playback
            try audioSession.setCategory(.playback, mode: .default, options: [])
            print("🎵 MOONNEST_LOG: Audio session category set to playback")
            
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("🎵 MOONNEST_LOG: Audio session activated successfully")
            
            // Re-establish remote control events (critical for background audio)
            UIApplication.shared.beginReceivingRemoteControlEvents()
            print("🎵 MOONNEST_LOG: Remote control events enabled")
            
            // Stop any currently playing audio
            audioPlayer?.stop()
            print("🎵 MOONNEST_LOG: Stopped previous audio player")
            
            // Create and configure new audio player
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            print("🎵 MOONNEST_LOG: Created new AVAudioPlayer")
            
            audioPlayer?.numberOfLoops = -1  // Loop indefinitely
            audioPlayer?.volume = defaultVolume
            print("🎵 MOONNEST_LOG: Configured player - loops: -1, volume: \(defaultVolume)")
            
            // Prepare to play
            let prepareSuccess = audioPlayer?.prepareToPlay() ?? false
            print("🎵 MOONNEST_LOG: Audio prepare success: \(prepareSuccess)")
            
            // If prepare fails, try again after session activation
            if !prepareSuccess {
                print("🎵 MOONNEST_LOG: Initial prepare failed, retrying after session activation")
                
                // Request audio session control with proper options for background audio
                try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])
                print("🎵 MOONNEST_LOG: Re-activated audio session for retry")
                
                let retryPrepare = audioPlayer?.prepareToPlay() ?? false
                print("🎵 MOONNEST_LOG: Retry prepare success: \(retryPrepare)")
            }
            
            // Start playback
            print("🎵 MOONNEST_LOG: Attempting to start playback...")
            let success = audioPlayer?.play() ?? false
            print("🎵 MOONNEST_LOG: Audio player play() returned: \(success)")
            
            if success {
                isPlaying = true
                currentSound = soundName
                updateNowPlayingInfo(soundName: soundName)
                print("🎵 MOONNEST_LOG: ✅ Successfully started playing \(soundName)")
                print("🎵 MOONNEST_LOG: Audio player isPlaying: \(audioPlayer?.isPlaying ?? false)")
                print("🎵 MOONNEST_LOG: Final session category: \(audioSession.category)")
                print("🎵 MOONNEST_LOG: Session is active: \(!audioSession.isOtherAudioPlaying)")
                
                // Additional diagnostics
                if let player = audioPlayer {
                    print("🎵 MOONNEST_LOG: Player duration: \(player.duration)")
                    print("🎵 MOONNEST_LOG: Player current time: \(player.currentTime)")
                    print("🎵 MOONNEST_LOG: Player number of loops: \(player.numberOfLoops)")
                }
                
                // Start monitoring audio state every second
                startAudioStateMonitoring()
            } else {
                print("🎵 MOONNEST_LOG: ❌ Failed to start audio playback")
                
                // Additional diagnostics on failure
                print("🎵 MOONNEST_LOG: Player exists: \(audioPlayer != nil)")
                if let player = audioPlayer {
                    print("🎵 MOONNEST_LOG: Player isPlaying: \(player.isPlaying)")
                    print("🎵 MOONNEST_LOG: Player duration: \(player.duration)")
                }
            }
            
        } catch {
            print("🎵 MOONNEST_LOG: ❌ Error setting up audio for playback: \(error)")
            if let nsError = error as NSError? {
                print("🎵 MOONNEST_LOG: Error domain: \(nsError.domain)")
                print("🎵 MOONNEST_LOG: Error code: \(nsError.code)")
                print("🎵 MOONNEST_LOG: Error description: \(nsError.localizedDescription)")
            }
        }
    }
    
    private func startAudioStateMonitoring() {
        print("🎵 MOONNEST_LOG: Starting audio state monitoring")
        audioStateMonitor?.invalidate()
        audioStateMonitor = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let player = self.audioPlayer {
                let playerIsPlaying = player.isPlaying
                let publishedIsPlaying = self.isPlaying
                let currentTime = player.currentTime
                
                // Only log if there's a mismatch or every 10 seconds
                let shouldLog = playerIsPlaying != publishedIsPlaying || Int(currentTime) % 10 == 0
                
                if shouldLog {
                    print("🎵 MOONNEST_LOG: Monitor - Player: \(playerIsPlaying), Published: \(publishedIsPlaying), Time: \(currentTime)")
                }
                
                // Detect if audio stopped unexpectedly
                if publishedIsPlaying && !playerIsPlaying {
                    print("🎵 MOONNEST_LOG: ⚠️ Audio stopped unexpectedly! Published: \(publishedIsPlaying), Player: \(playerIsPlaying)")
                    DispatchQueue.main.async {
                        self.isPlaying = false
                    }
                }
            }
        }
    }
    
    func stopSound() {
        print("🎵 MOONNEST_LOG: stopSound called")
        audioStateMonitor?.invalidate()
        audioStateMonitor = nil
        audioPlayer?.stop()
        isPlaying = false
        currentSound = nil
        cancelTimer()
        
        // Clear Now Playing info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    func scheduleStop(after duration: TimeInterval) {
        cancelTimer()
        
        timeRemaining = duration
        timerActive = true
        
        // Timer to stop the sound
        stopTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.stopSound()
            }
        }
        
        // Countdown timer to update remaining time
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.timeRemaining -= 1
                if self.timeRemaining <= 0 {
                    self.cancelTimer()
                }
            }
        }
    }
    
    func cancelTimer() {
        stopTimer?.invalidate()
        countdownTimer?.invalidate()
        stopTimer = nil
        countdownTimer = nil
        timerActive = false
        timeRemaining = 0
    }
    
    var formattedTimeRemaining: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func toggleSound(_ soundName: String) {
        NSLog("MOONNEST_LOG: toggleSound called for %@", soundName)
        print("MOONNEST_LOG: toggleSound called for \(soundName)")
        print("MOONNEST_LOG: Current state - isPlaying: \(isPlaying), currentSound: \(currentSound ?? "none")")
        
        if isPlaying && currentSound == soundName {
            print("🎵 MOONNEST_LOG: Stopping current sound")
            stopSound()
        } else {
            print("🎵 MOONNEST_LOG: Starting new sound")
            playSound(soundName)
        }
    }
    
    
    deinit {
        audioStateMonitor?.invalidate()
        audioPlayer?.stop()
        cancelTimer()
    }
}
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
    
    init() {
        setupAudioSession()
        setupAudioSessionNotifications()
        setupRemoteCommandCenter()
        loadVolumeFromUserDefaults()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Configure for background audio playback with recommended options
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
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
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
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
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            print("Could not find sound file: \(soundName).mp3")
            return
        }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Ensure audio session is configured and active for background playback
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Stop any currently playing audio
            audioPlayer?.stop()
            
            // Create and configure new audio player
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1  // Loop indefinitely
            audioPlayer?.volume = defaultVolume
            
            // Prepare to play
            audioPlayer?.prepareToPlay()
            
            // Start playback
            let success = audioPlayer?.play() ?? false
            
            if success {
                isPlaying = true
                currentSound = soundName
                updateNowPlayingInfo(soundName: soundName)
                print("Started playing \(soundName) in background-capable mode")
                print("Audio player is playing: \(audioPlayer?.isPlaying ?? false)")
                print("Audio session category: \(audioSession.category)")
                print("Audio session active: \(audioSession.isOtherAudioPlaying == false)")
            } else {
                print("Failed to start audio playback")
            }
            
        } catch {
            print("Error setting up audio for playback: \(error)")
        }
    }
    
    func stopSound() {
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
        if isPlaying && currentSound == soundName {
            stopSound()
        } else {
            playSound(soundName)
        }
    }
    
    
    deinit {
        audioPlayer?.stop()
        cancelTimer()
    }
}
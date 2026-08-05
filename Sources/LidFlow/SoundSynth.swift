import Foundation
import AVFoundation

class SoundSynth {
    static let shared = SoundSynth()
    
    // Settings
    var isDoorSoundsEnabled = true
    var isThereminEnabled = false {
        didSet {
            if isThereminEnabled {
                startThereminEngine()
            } else {
                stopThereminEngine()
            }
        }
    }
    
    var doorSoundVolume: Float = 0.5 {
        didSet {
            creakPlayer?.volume = doorSoundVolume
            slamPlayer?.volume = doorSoundVolume
        }
    }
    
    var thereminVolume: Float = 0.3
    var oscillatorType = "Sine" // Sine, Triangle, Sawtooth
    
    // Audio Players for Door Sounds
    private var creakPlayer: AVAudioPlayer?
    private var slamPlayer: AVAudioPlayer?
    
    // AVAudioEngine for Theremin
    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var mixer: AVAudioMixerNode?
    
    // Theremin State Variables
    private var phase: Double = 0.0
    private var targetFrequency: Double = 440.0
    private var currentFrequency: Double = 440.0
    private var targetAmplitude: Double = 0.0
    private var currentAmplitude: Double = 0.0
    
    private init() {
        setupDoorSounds()
        setupThereminEngine()
    }
    
    // MARK: - Door Sounds Setup & Playback
    private func setupDoorSounds() {
        let creakWav = generateDoorCreakWav()
        let slamWav = generateDoorSlamWav()
        
        do {
            creakPlayer = try AVAudioPlayer(data: creakWav)
            creakPlayer?.prepareToPlay()
            creakPlayer?.volume = doorSoundVolume
            
            slamPlayer = try AVAudioPlayer(data: slamWav)
            slamPlayer?.prepareToPlay()
            slamPlayer?.volume = doorSoundVolume
        } catch {
            print("Failed to initialize door sound players: \(error)")
        }
    }
    
    func playOpenSound() {
        guard isDoorSoundsEnabled else { return }
        creakPlayer?.currentTime = 0
        creakPlayer?.play()
    }
    
    func playCloseSound() {
        guard isDoorSoundsEnabled else { return }
        slamPlayer?.currentTime = 0
        slamPlayer?.play()
    }
    
    // MARK: - Theremin Engine Setup
    private func setupThereminEngine() {
        let audioEngine = AVAudioEngine()
        self.engine = audioEngine
        
        let localMixer = AVAudioMixerNode()
        audioEngine.attach(localMixer)
        audioEngine.connect(localMixer, to: audioEngine.outputNode, format: nil)
        self.mixer = localMixer
        
        let sampleRate = 44100.0
        
        // Setup raw PCM source node
        let node = AVAudioSourceNode { [weak self] (silence, timeStamp, frameCount, outputData) -> OSStatus in
            guard let self = self else { return noErr }
            
            let abl = UnsafeMutableAudioBufferListPointer(outputData)
            let bufferPointer = abl.first
            let buf = UnsafeMutableBufferPointer<Float>(bufferPointer!)
            
            for frame in 0..<Int(frameCount) {
                // Interpolate frequency and amplitude to prevent clicks/pop sounds
                self.currentFrequency += (self.targetFrequency - self.currentFrequency) * 0.005
                self.currentAmplitude += (self.targetAmplitude - self.currentAmplitude) * 0.01
                
                let t = self.phase / sampleRate
                let freq = self.currentFrequency
                let amp = self.currentAmplitude * Double(self.thereminVolume)
                
                var signal = 0.0
                switch self.oscillatorType {
                case "Triangle":
                    // Triangle wave: goes linearly -1 to 1 and back
                    signal = 2.0 * abs(2.0 * (t * freq - floor(t * freq + 0.5))) - 1.0
                case "Sawtooth":
                    // Sawtooth wave: goes linearly -1 to 1
                    signal = 2.0 * (t * freq - floor(t * freq + 0.5))
                default: // Sine
                    signal = sin(2.0 * Double.pi * freq * t)
                }
                
                buf[frame] = Float(signal * amp)
                self.phase += 1.0
                
                // Wrap phase to prevent numerical overflow
                if self.phase >= sampleRate * 100.0 {
                    self.phase = 0.0
                }
            }
            return noErr
        }
        
        audioEngine.attach(node)
        audioEngine.connect(node, to: localMixer, format: nil)
        self.sourceNode = node
    }
    
    private func startThereminEngine() {
        guard let engine = engine, !engine.isRunning else { return }
        do {
            try engine.start()
            print("Theremin Audio Engine Started")
        } catch {
            print("Could not start audio engine: \(error)")
        }
    }
    
    private func stopThereminEngine() {
        engine?.stop()
        print("Theremin Audio Engine Stopped")
    }
    
    // MARK: - Real-time Theremin Control
    func updateTheremin(angle: Double, deltaAngle: Double) {
        guard isThereminEnabled else { return }
        
        // 1. Map Lid Angle to Target Frequency (Pitch)
        // MacBook open angle is normally 0° to 135°.
        // We map 10° to 135° -> 150Hz to 1100Hz (playable frequency range)
        let minAngle = 10.0
        let maxAngle = 135.0
        let clampedAngle = max(minAngle, min(maxAngle, angle))
        
        let minFreq = 180.0
        let maxFreq = 1000.0
        let progress = (clampedAngle - minAngle) / (maxAngle - minAngle)
        targetFrequency = minFreq + (maxFreq - minFreq) * progress
        
        // 2. Map screen movement speed (deltaAngle) to volume amplitude
        // If the screen is moving fast, play louder. If it's still, decay the sound to a quiet hum or silence.
        let movementIntensity = min(1.0, abs(deltaAngle) * 5.0) // normalize velocity
        
        if movementIntensity > 0.02 {
            targetAmplitude = 0.15 + (movementIntensity * 0.45)
        } else {
            // Decay to silence when MacBook is stationary
            targetAmplitude = max(0.0, targetAmplitude - 0.05)
        }
    }
    
    // MARK: - WAV Generation Utilities
    private func createWavHeader(sampleRate: Int, numChannels: Int, bitsPerSample: Int, dataSize: Int) -> Data {
        var header = Data()
        header.append("RIFF".data(using: .utf8)!)
        let fileSize = Int32(36 + dataSize)
        header.append(withUnsafeBytes(of: fileSize) { Data($0) })
        header.append("WAVE".data(using: .utf8)!)
        
        header.append("fmt ".data(using: .utf8)!)
        let subchunk1Size = Int32(16)
        header.append(withUnsafeBytes(of: subchunk1Size) { Data($0) })
        let audioFormat = Int16(1) // PCM
        header.append(withUnsafeBytes(of: audioFormat) { Data($0) })
        let numChannelsInt16 = Int16(numChannels)
        header.append(withUnsafeBytes(of: numChannelsInt16) { Data($0) })
        let sampleRateInt32 = Int32(sampleRate)
        header.append(withUnsafeBytes(of: sampleRateInt32) { Data($0) })
        let byteRate = Int32(sampleRate * numChannels * (bitsPerSample / 8))
        header.append(withUnsafeBytes(of: byteRate) { Data($0) })
        let blockAlign = Int16(numChannels * (bitsPerSample / 8))
        header.append(withUnsafeBytes(of: blockAlign) { Data($0) })
        let bitsPerSampleInt16 = Int16(bitsPerSample)
        header.append(withUnsafeBytes(of: bitsPerSampleInt16) { Data($0) })
        
        header.append("data".data(using: .utf8)!)
        let dataSizeInt32 = Int32(dataSize)
        header.append(withUnsafeBytes(of: dataSizeInt32) { Data($0) })
        
        return header
    }
    
    private func generateDoorCreakWav() -> Data {
        let sampleRate = 22050.0
        let duration = 1.6
        let totalSamples = Int(sampleRate * duration)
        var samples = [Int16]()
        
        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            
            // Creak stiction peaks (rubbing hinge frequency)
            let baseFreq = 780.0 - 220.0 * (t * t)
            
            // Friction pulses: the creaking click rate
            let pulseRate = 16.0 * exp(-1.1 * t)
            let pulseEnv = pow(max(0.0, cos(2.0 * Double.pi * pulseRate * t)), 4.0)
            
            let wave = sin(2.0 * Double.pi * baseFreq * t)
            let noise = Double.random(in: -1.0...1.0) * 0.16
            let decayEnv = 1.0 - (t / duration)
            
            let signal = (wave + noise) * pulseEnv * decayEnv
            let sample = Int16(signal * 20000.0)
            samples.append(sample)
        }
        
        let dataSize = samples.count * MemoryLayout<Int16>.size
        var audioData = createWavHeader(sampleRate: Int(sampleRate), numChannels: 1, bitsPerSample: 16, dataSize: dataSize)
        samples.withUnsafeBufferPointer { audioData.append($0) }
        return audioData
    }
    
    private func generateDoorSlamWav() -> Data {
        let sampleRate = 22050.0
        let duration = 0.45
        let totalSamples = Int(sampleRate * duration)
        var samples = [Int16]()
        
        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            
            // Deep low frequency thump of door frame
            let thumpFreq = 62.0 * exp(-13.0 * t)
            let thump = sin(2.0 * Double.pi * thumpFreq * t) * exp(-14.0 * t)
            
            // Mid range resonance of the door wood
            let woodResonance = sin(2.0 * Double.pi * 170.0 * t) * exp(-28.0 * t)
            
            // Latch metal click
            let click = sin(2.0 * Double.pi * 1300.0 * t) * exp(-180.0 * t)
            
            // Noise impact echo
            let noise = Double.random(in: -1.0...1.0) * exp(-20.0 * t)
            
            let signal = (thump * 0.68) + (woodResonance * 0.18) + (click * 0.08) + (noise * 0.06)
            let sample = Int16(signal * 25000.0)
            samples.append(sample)
        }
        
        let dataSize = samples.count * MemoryLayout<Int16>.size
        var audioData = createWavHeader(sampleRate: Int(sampleRate), numChannels: 1, bitsPerSample: 16, dataSize: dataSize)
        samples.withUnsafeBufferPointer { audioData.append($0) }
        return audioData
    }
}

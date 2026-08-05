import SwiftUI

struct LidFlowView: View {
    @StateObject private var sensor = LidSensor()
    @State private var lastAngle: Double = 0.0
    @State private var doorSoundsEnabled = true
    @State private var thereminEnabled = false
    @State private var doorVolume: Double = 0.5
    @State private var thereminVolume: Double = 0.3
    @State private var oscillatorType = "Sine"
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HeaderView(isConnected: sensor.isConnected)
            
            // Real-time Visualizer Panel
            VisualizerPanel(angle: sensor.angle)
            
            // Controls List
            VStack(spacing: 12) {
                // Door Sounds Config Card
                DoorSoundsCard(
                    enabled: $doorSoundsEnabled,
                    volume: $doorVolume
                )
                
                // Theremin Config Card
                ThereminCard(
                    enabled: $thereminEnabled,
                    volume: $thereminVolume,
                    oscillatorType: $oscillatorType
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Footer
            FooterView()
        }
        .frame(width: 380, height: 530)
        .padding(.vertical, 16)
        .onAppear {
            sensor.startMonitoring()
            // Set initial volumes
            SoundSynth.shared.doorSoundVolume = Float(doorVolume)
            SoundSynth.shared.thereminVolume = Float(thereminVolume)
        }
        .onDisappear {
            sensor.stopMonitoring()
        }
        .onChange(of: sensor.angle) { newAngle in
            let delta = newAngle - lastAngle
            lastAngle = newAngle
            
            // Trigger door sounds on transitions
            // Door opening: goes from 0 up
            if lastAngle <= 5.0 && newAngle > 5.0 {
                SoundSynth.shared.playOpenSound()
            }
            // Door closing: goes down to 0
            if lastAngle > 5.0 && newAngle <= 5.0 {
                SoundSynth.shared.playCloseSound()
            }
            
            // Update Theremin synth parameters
            SoundSynth.shared.updateTheremin(angle: newAngle, deltaAngle: delta)
        }
    }
}

// MARK: - Header
struct HeaderView: View {
    let isConnected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "laptopcomputer")
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("LidFlow")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(isConnected ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                    Text(isConnected ? "Sensor Connected" : "Sensor Offline")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("v1.0.0")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(4)
        }
        .padding(.horizontal)
    }
}

// MARK: - Visualizer Panel
struct VisualizerPanel: View {
    let angle: Double
    
    var body: some View {
        VStack(spacing: 12) {
            // Large Centered Display
            VStack(spacing: 0) {
                Text(String(format: "%.1f°", angle))
                    .font(.system(size: 64, weight: .thin, design: .rounded))
                    .foregroundColor(.primary)
                Text("CURRENT ANGLE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(2)
            }
            
            // Dynamic Laptop Graphic
            ZStack(alignment: .bottomLeading) {
                // Lower Body (Base)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.primary.opacity(0.15))
                    .frame(width: 140, height: 6)
                    .offset(x: 10, y: 0)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.primary.opacity(0.7))
                    .frame(width: 130, height: 2)
                    .offset(x: 15, y: -4)
                
                // Screen (Lid) - rotates around the bottom leading edge
                ZStack(alignment: .leading) {
                    // Back Bezel
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.primary.opacity(0.85))
                        .frame(width: 136, height: 4)
                    
                    // Display glowing screen line
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.accentColor)
                        .frame(width: 132, height: 2)
                        .offset(x: 2, y: 1)
                        .opacity(angle > 5.0 ? 1.0 : 0.0)
                }
                .rotationEffect(.degrees(-angle), anchor: .leading)
                .offset(x: 10, y: -4)
                
                // Hinge Joint pin
                Circle()
                    .fill(Color.primary.opacity(0.9))
                    .frame(width: 8, height: 8)
                    .offset(x: 6, y: -2)
            }
            .frame(width: 160, height: 120)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.secondary.opacity(0.06))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Door Sounds Card
struct DoorSoundsCard: View {
    @Binding var enabled: Bool
    @Binding var volume: Double
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Door SFX (LidDoor)", systemImage: "door.left.hand.open")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Toggle("", isOn: $enabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .onChange(of: enabled) { val in
                        SoundSynth.shared.isDoorSoundsEnabled = val
                    }
            }
            
            if enabled {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.1")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                    
                    Slider(value: $volume, in: 0...1) { _ in
                        SoundSynth.shared.doorSoundVolume = Float(volume)
                    }
                    
                    Image(systemName: "speaker.wave.3")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                    
                    Spacer(minLength: 12)
                    
                    // Demo sound triggers
                    HStack(spacing: 6) {
                        Button(action: { SoundSynth.shared.playOpenSound() }) {
                            Text("Open")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button(action: { SoundSynth.shared.playCloseSound() }) {
                            Text("Slam")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Theremin Card
struct ThereminCard: View {
    @Binding var enabled: Bool
    @Binding var volume: Double
    @Binding var oscillatorType: String
    
    let waveTypes = ["Sine", "Triangle", "Sawtooth"]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Theremin Synth", systemImage: "waveform.path.ecg.radial")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Toggle("", isOn: $enabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .onChange(of: enabled) { val in
                        SoundSynth.shared.isThereminEnabled = val
                    }
            }
            
            if enabled {
                VStack(spacing: 12) {
                    // Volume Control
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.1")
                            .foregroundColor(.secondary)
                            .font(.system(size: 11))
                        
                        Slider(value: $volume, in: 0...1) { _ in
                            SoundSynth.shared.thereminVolume = Float(volume)
                        }
                        
                        Image(systemName: "speaker.wave.3")
                            .foregroundColor(.secondary)
                            .font(.system(size: 11))
                    }
                    
                    // Wave type picker
                    HStack {
                        Text("Wave Type")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("", selection: $oscillatorType) {
                            ForEach(waveTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 220)
                        .onChange(of: oscillatorType) { val in
                            SoundSynth.shared.oscillatorType = val
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Footer
struct FooterView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Interactive MacBook Hinge Controller")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            Text("Close lid to play Slam / Move lid to play Theremin & Creak")
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.8))
        }
    }
}

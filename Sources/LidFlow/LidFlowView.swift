import SwiftUI

struct LidFlowView: View {
    @StateObject private var sensor = LidSensor()
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
            VisualizerPanel(angle: sensor.angle, speed: sensor.speed)
            
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

// MARK: - MacBook Base Shape
struct MacBookBase: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + 1))
        path.addLine(to: CGPoint(x: rect.maxX - 12, y: rect.minY + 4))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.minY + 4))
        path.addLine(to: CGPoint(x: rect.minX + 4, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY + 1), control: CGPoint(x: rect.minX, y: rect.maxY))
        return path
    }
}

// MARK: - Visualizer Panel
struct VisualizerPanel: View {
    let angle: Double
    let speed: Double
    
    var body: some View {
        VStack(spacing: 8) {
            // Large Centered Display
            VStack(spacing: 4) {
                Text(String(format: "%.1f°", angle))
                    .font(.system(size: 64, weight: .thin, design: .rounded))
                    .foregroundColor(.primary)
                
                // Speed indicator below the angle
                HStack(spacing: 4) {
                    Image(systemName: "gauge.with.needle")
                        .font(.system(size: 11))
                    Text(speed > 0.5 ? String(format: "Speed: %.1f°/s", speed) : "Stationary")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
                .foregroundColor(speed > 0.5 ? .accentColor : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(6)
                
                Text("CURRENT HINGE ANGLE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(2)
                    .padding(.top, 6)
            }
            
            // Large spacer to prevent screen lid overlapping with text
            Spacer(minLength: 32)
            
            // Dynamic Laptop Graphic
            ZStack(alignment: .bottomLeading) {
                // Lower Body (Base)
                ZStack(alignment: .bottomLeading) {
                    // Rubber feet
                    HStack {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.primary.opacity(0.8))
                            .frame(width: 10, height: 2)
                        Spacer()
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.primary.opacity(0.8))
                            .frame(width: 10, height: 2)
                    }
                    .frame(width: 120)
                    .offset(x: 10, y: 7)
                    
                    // Tapered Chassis
                    MacBookBase()
                        .fill(LinearGradient(colors: [Color.primary.opacity(0.18), Color.primary.opacity(0.08)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 140, height: 6)
                }
                .offset(x: 10, y: 0)
                
                // Screen (Lid) - rotates around the bottom leading edge
                ZStack(alignment: .leading) {
                    // Aluminum back
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(LinearGradient(colors: [Color.primary.opacity(0.4), Color.primary.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 135, height: 3.5)
                    
                    // Glass bezel
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.primary.opacity(0.85))
                        .frame(width: 133, height: 2.2)
                        .offset(x: 1, y: 0.6)
                    
                    // Glowing screen active line
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 130, height: 1.2)
                        .offset(x: 2, y: 1.1)
                        .opacity(angle > 3.0 ? 1.0 : 0.0)
                }
                .rotationEffect(.degrees(-angle), anchor: .leading)
                .offset(x: 10, y: -4)
                
                // Hinge Joint pin
                Circle()
                    .fill(Color.primary.opacity(0.9))
                    .frame(width: 8, height: 8)
                    .offset(x: 6, y: -2)
            }
            .frame(width: 160, height: 140)
            .padding(.bottom, 8)
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

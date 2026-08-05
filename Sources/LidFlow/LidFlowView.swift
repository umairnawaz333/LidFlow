import SwiftUI

struct LidFlowView: View {
    @StateObject private var sensor = LidSensor()
    @State private var doorSoundsEnabled = true
    @State private var thereminEnabled = false
    @State private var doorVolume: Double = 0.5
    @State private var thereminVolume: Double = 0.3
    @State private var oscillatorType = "Sine"
    
    var body: some View {
        HStack(spacing: 0) {
            // LEFT PANE: Dark Visualizer Canvas
            VisualizerCanvas(
                angle: sensor.angle,
                speed: sensor.speed,
                isConnected: sensor.isConnected
            )
            
            Divider()
                .background(Color.primary.opacity(0.1))
            
            // RIGHT PANE: Control Sidebar
            ControlSidebar(
                doorSoundsEnabled: $doorSoundsEnabled,
                doorVolume: $doorVolume,
                thereminEnabled: $thereminEnabled,
                thereminVolume: $thereminVolume,
                oscillatorType: $oscillatorType,
                isConnected: sensor.isConnected
            )
            .frame(width: 320)
        }
        .frame(
            minWidth: 680, idealWidth: 750, maxWidth: .infinity,
            minHeight: 400, idealHeight: 480, maxHeight: .infinity
        )
        .onAppear {
            sensor.startMonitoring()
            SoundSynth.shared.doorSoundVolume = Float(doorVolume)
            SoundSynth.shared.thereminVolume = Float(thereminVolume)
        }
        .onDisappear {
            sensor.stopMonitoring()
        }
    }
}

// MARK: - Left Pane: Visualizer Canvas
struct VisualizerCanvas: View {
    let angle: Double
    let speed: Double
    let isConnected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Status Bar
            HStack {
                Text("LidFlow Hinge Utility")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 5) {
                    Circle()
                        .fill(isConnected ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                    Text(isConnected ? "Sensor Connected" : "Sensor Offline")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Spacer()
            
            // Center Metrics Display
            VStack(spacing: 6) {
                // Large blue angle text matching custom design (bright neon blue)
                Text(String(format: "%.1f°", angle))
                    .font(.system(size: 84, weight: .thin, design: .rounded))
                    .foregroundColor(Color(red: 0.0, green: 0.5, blue: 1.0))
                
                // Speed & Lid status
                VStack(spacing: 4) {
                    Text(String(format: "Velocity: %02d deg/s", Int(round(speed))))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Text(getLidStateText(angle: angle))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.8))
                        .tracking(1)
                }
            }
            
            Spacer()
            
            // Physical Simulated Hinge Graphic (Tuned to fit nicely)
            ZStack(alignment: .bottomLeading) {
                // Lower Body (Base)
                ZStack(alignment: .bottomLeading) {
                    // Rubber feet
                    HStack {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.primary.opacity(0.8))
                            .frame(width: 8, height: 1.5)
                        Spacer()
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.primary.opacity(0.8))
                            .frame(width: 8, height: 1.5)
                    }
                    .frame(width: 80)
                    .offset(x: 10, y: 5)
                    
                    // Tapered Chassis
                    MacBookBase()
                        .fill(LinearGradient(colors: [Color.primary.opacity(0.18), Color.primary.opacity(0.08)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 100, height: 5)
                }
                .offset(x: 10, y: 0)
                
                // Screen (Lid) - rotates around the bottom leading edge
                ZStack(alignment: .leading) {
                    // Aluminum back
                    RoundedRectangle(cornerRadius: 1.2)
                        .fill(LinearGradient(colors: [Color.primary.opacity(0.4), Color.primary.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 95, height: 3.0)
                    
                    // Glass bezel
                    RoundedRectangle(cornerRadius: 0.8)
                        .fill(Color.primary.opacity(0.85))
                        .frame(width: 93, height: 1.8)
                        .offset(x: 1, y: 0.6)
                    
                    // Glowing screen active line
                    RoundedRectangle(cornerRadius: 0.4)
                        .fill(LinearGradient(colors: [Color(red: 0.0, green: 0.5, blue: 1.0), Color.cyan], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 90, height: 1.0)
                        .offset(x: 2, y: 1.0)
                        .opacity(angle > 3.0 ? 1.0 : 0.0)
                }
                .rotationEffect(.degrees(-angle), anchor: .leading)
                .offset(x: 10, y: -3.5)
                
                // Hinge Joint pin
                Circle()
                    .fill(Color.primary.opacity(0.9))
                    .frame(width: 6, height: 6)
                    .offset(x: 7, y: -2)
            }
            .frame(width: 120, height: 100)
            .padding(.bottom, 32)
        }
        .background(Color.black.opacity(0.15))
    }
    
    private func getLidStateText(angle: Double) -> String {
        if angle <= 5.0 {
            return "LID CLOSED"
        } else if angle < 30.0 {
            return "LID SLIGHTLY OPEN"
        } else if angle < 85.0 {
            return "LID HALFWAY OPEN"
        } else if angle < 125.0 {
            return "LID MOSTLY OPEN"
        } else {
            return "LID FULLY OPEN"
        }
    }
}

// MARK: - MacBook Base Shape
struct MacBookBase: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + 1))
        path.addLine(to: CGPoint(x: rect.maxX - 10, y: rect.minY + 3.5))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.minY + 3.5))
        path.addLine(to: CGPoint(x: rect.minX + 3, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY + 1), control: CGPoint(x: rect.minX, y: rect.maxY))
        return path
    }
}

// MARK: - Right Pane: Control Sidebar
struct ControlSidebar: View {
    @Binding var doorSoundsEnabled: Bool
    @Binding var doorVolume: Double
    @Binding var thereminEnabled: Bool
    @Binding var thereminVolume: Double
    @Binding var oscillatorType: String
    let isConnected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Sidebar Header / Actions
            HStack {
                Text("CONTROLS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(1.5)
                
                Spacer()
                
                Text("v1.0.0")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
                .background(Color.primary.opacity(0.06))
            
            // Scrollable Settings Cards
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    DoorSoundsCard(
                        enabled: $doorSoundsEnabled,
                        volume: $doorVolume
                    )
                    
                    ThereminCard(
                        enabled: $thereminEnabled,
                        volume: $thereminVolume,
                        oscillatorType: $oscillatorType
                    )
                }
                .padding(16)
            }
        }
        .background(Color.secondary.opacity(0.02))
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
                VStack(spacing: 10) {
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
                    }
                    
                    // Demo sound triggers
                    HStack(spacing: 8) {
                        Button(action: { SoundSynth.shared.playOpenSound() }) {
                            Text("Test Open")
                                .font(.system(size: 10, weight: .medium))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button(action: { SoundSynth.shared.playCloseSound() }) {
                            Text("Test Slam")
                                .font(.system(size: 10, weight: .medium))
                                .frame(maxWidth: .infinity)
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
                        .frame(width: 170)
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

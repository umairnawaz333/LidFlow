import Foundation
import IOKit.hid
import Combine

class LidSensor: ObservableObject {
    @Published var angle: Double = 0.0
    @Published var speed: Double = 0.0
    @Published var isConnected: Bool = false
    
    private var manager: IOHIDManager?
    private var device: IOHIDDevice?
    private var timer: Timer?
    
    init() {
        setupHID()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func setupHID() {
        let managerRef = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        self.manager = managerRef
        
        let matchingDict: [String: Any] = [
            kIOHIDVendorIDKey: 0x05ac,
            kIOHIDProductIDKey: 0x8104,
            kIOHIDPrimaryUsagePageKey: 0x0020,
            kIOHIDPrimaryUsageKey: 0x008a
        ]
        
        IOHIDManagerSetDeviceMatching(managerRef, matchingDict as CFDictionary)
        let openResult = IOHIDManagerOpen(managerRef, IOOptionBits(kIOHIDOptionsTypeNone))
        
        guard openResult == kIOReturnSuccess else {
            print("Failed to open HID Manager: \(openResult)")
            return
        }
        
        guard let devices = IOHIDManagerCopyDevices(managerRef) as? Set<IOHIDDevice>, let firstDevice = devices.first else {
            print("Lid angle sensor device not found")
            return
        }
        
        self.device = firstDevice
        self.isConnected = true
        print("Lid Sensor connected successfully")
    }
    
    private var lastAngle: Double = 0.0
    
    func startMonitoring() {
        guard device != nil else { return }
        
        // Read initially
        readAngle()
        
        // Poll at 20Hz (50ms)
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.readAngle()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func readAngle() {
        guard let device = device else { return }
        
        var report = [UInt8](repeating: 0, count: 8)
        var reportLength = CFIndex(8)
        
        // Try Report ID 7 first (centidegrees precision, e.g. 122.73)
        var result = IOHIDDeviceGetReport(
            device,
            kIOHIDReportTypeFeature,
            7,
            &report,
            &reportLength
        )
        
        var decodedAngle: Double? = nil
        
        if result == kIOReturnSuccess && reportLength >= 3 {
            let rawValue = UInt16(report[1]) | (UInt16(report[2]) << 8)
            let val = Double(rawValue) * 0.01
            if val >= 0 && val <= 360 {
                decodedAngle = val
            }
        } else {
            // Fallback to Report ID 1 (integer precision or legacy centidegrees)
            reportLength = CFIndex(8)
            result = IOHIDDeviceGetReport(
                device,
                kIOHIDReportTypeFeature,
                1,
                &report,
                &reportLength
            )
            
            if result == kIOReturnSuccess && reportLength >= 3 {
                let rawValue = UInt16(report[1]) | (UInt16(report[2]) << 8)
                var val = Double(rawValue)
                if rawValue > 360 {
                    val = Double(rawValue) * 0.01
                }
                if val >= 0 && val <= 360 {
                    decodedAngle = val
                }
            }
        }
        
        // Dispatch updates
        DispatchQueue.main.async {
            let current = decodedAngle ?? self.angle
            let delta = current - self.lastAngle
            self.lastAngle = current
            
            self.angle = current
            
            // Calculate and smooth movement speed (degrees/second)
            let rawSpeed = abs(delta) / 0.05
            self.speed = self.speed * 0.75 + rawSpeed * 0.25
            
            // Trigger audio controllers with real-time delta (including 0 when stationary)
            SoundSynth.shared.updateTheremin(angle: current, deltaAngle: delta)
            SoundSynth.shared.updateLidMove(angle: current, deltaAngle: delta)
        }
    }
}

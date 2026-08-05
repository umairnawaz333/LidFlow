import Foundation
import IOKit.hid
import Combine

class LidSensor: ObservableObject {
    @Published var angle: Double = 0.0
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
        
        if result == kIOReturnSuccess && reportLength >= 3 {
            let rawValue = UInt16(report[1]) | (UInt16(report[2]) << 8)
            let decodedAngle = Double(rawValue) * 0.01
            if decodedAngle >= 0 && decodedAngle <= 360 {
                DispatchQueue.main.async {
                    self.angle = decodedAngle
                }
                return
            }
        }
        
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
            var decodedAngle = Double(rawValue)
            if rawValue > 360 {
                decodedAngle = Double(rawValue) * 0.01
            }
            if decodedAngle >= 0 && decodedAngle <= 360 {
                DispatchQueue.main.async {
                    self.angle = decodedAngle
                }
            }
        }
    }
}

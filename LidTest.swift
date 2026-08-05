import Foundation
import IOKit

func getClamshellState() -> Bool? {
    let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
    guard service != 0 else {
        print("Failed to get IOPMrootDomain service")
        return nil
    }
    defer {
        IOObjectRelease(service)
    }
    
    let property = IORegistryEntryCreateCFProperty(service, "AppleClamshellState" as CFString, kCFAllocatorDefault, 0)
    guard let value = property?.takeRetainedValue() else {
        print("Failed to read AppleClamshellState property")
        return nil
    }
    
    // AppleClamshellState is boolean-like (either true/false or 1/0)
    if let boolVal = value as? Bool {
        return boolVal
    } else if let numVal = value as? NSNumber {
        return numVal.boolValue
    }
    
    return nil
}

print("Querying MacBook Lid State...")
if let state = getClamshellState() {
    print("AppleClamshellState: \(state) (Lid is \(state ? "CLOSED" : "OPEN"))")
} else {
    print("Could not retrieve lid state. Are you running on a MacBook?")
}

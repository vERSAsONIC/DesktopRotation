import Foundation
import CoreGraphics

/// Rotates displays through the private MonitorPanel framework (the same
/// mechanism System Settings > Displays uses). Loaded at runtime via dlopen so
/// nothing links against the private framework at build time.
enum DisplayRotator {
    private static let loaded: Bool = {
        dlopen("/System/Library/PrivateFrameworks/MonitorPanel.framework/MonitorPanel", RTLD_NOW) != nil
    }()

    /// The MPDisplay object for the main display, or nil if unavailable.
    private static func mainDisplay() -> NSObject? {
        guard loaded, let mgrClass = NSClassFromString("MPDisplayMgr") as? NSObject.Type else { return nil }
        let mainID = Int32(bitPattern: CGMainDisplayID())
        let displays = mgrClass.init().value(forKey: "displays") as? [NSObject] ?? []
        return displays.first { ($0.value(forKey: "displayID") as? Int32) == mainID }
            ?? displays.first { ($0.value(forKey: "canChangeOrientation") as? Bool) == true }
    }

    static var currentRotation: Int {
        Int(CGDisplayRotation(CGMainDisplayID()))
    }

    /// Sets the main display to `degrees` (0/90/180/270) and waits briefly for
    /// the asynchronous change to land. Returns whether the rotation took.
    @discardableResult
    static func rotate(to degrees: Int) -> Bool {
        guard let display = mainDisplay() else { return false }
        let id = CGMainDisplayID()
        display.setValue(degrees, forKey: "orientation")
        let deadline = Date().addingTimeInterval(5)
        while Int(CGDisplayRotation(id)) != degrees && Date() < deadline {
            usleep(50_000)
        }
        return Int(CGDisplayRotation(id)) == degrees
    }

    /// Toggles between standard (0°) and 90°.
    @discardableResult
    static func toggle() -> Bool {
        rotate(to: currentRotation == 0 ? 90 : 0)
    }
}

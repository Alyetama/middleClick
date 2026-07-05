import AppKit
import CoreGraphics
import CMultitouch

// Top-level C callback. Must not capture context so it can be passed as a
// plain C function pointer. Forwards to the shared detector.
private func mtCallback(_ device: Int32,
                        _ data: UnsafeMutablePointer<Finger>?,
                        _ nFingers: Int32,
                        _ timestamp: Double,
                        _ frame: Int32) -> Int32 {
    GestureDetector.shared.handle(fingers: data, count: Int(nFingers))
    return 0
}

/// Watches the trackpad for an N-finger tap and emits a synthetic middle click.
final class GestureDetector {
    static let shared = GestureDetector()
    private init() {}

    private var devices: [MTDeviceRef] = []

    // Set MIDDLECLICK_DEBUG=1 to log each gesture's outcome to the console.
    private let debug = ProcessInfo.processInfo.environment["MIDDLECLICK_DEBUG"] == "1"

    // Gesture state (touched only from the multitouch callback thread).
    private var touchStart: CFAbsoluteTime = 0
    private var maxFingers = 0
    private var startX: Float = 0
    private var startY: Float = 0
    private var moved = false

    // MARK: Lifecycle

    func start() {
        registerDevices()
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(wake),
            name: NSWorkspace.didWakeNotification, object: nil)
    }

    @objc private func wake() {
        // Devices stop delivering frames after sleep; re-arm them.
        stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.registerDevices()
        }
    }

    private func registerDevices() {
        stop()
        let maxDevices = 16
        var buf = [MTDeviceRef?](repeating: nil, count: maxDevices)
        let n = buf.withUnsafeMutableBufferPointer { p in
            MT_GetDevices(p.baseAddress, Int32(maxDevices))
        }
        var list = Array(buf.prefix(Int(n)).compactMap { $0 })
        if list.isEmpty, let def = MTDeviceCreateDefault() {
            list.append(def)
        }
        for dev in list {
            MTRegisterContactFrameCallback(dev, mtCallback)
            MTDeviceStart(dev, 0)
        }
        devices = list
    }

    func stop() {
        for dev in devices {
            MTUnregisterContactFrameCallback(dev, mtCallback)
            MTDeviceStop(dev)
        }
        devices.removeAll()
        resetGesture()
    }

    private func resetGesture() {
        touchStart = 0
        maxFingers = 0
        moved = false
    }

    // MARK: Detection

    fileprivate func handle(fingers: UnsafeMutablePointer<Finger>?, count: Int) {
        let s = Settings.shared
        guard s.enabled else { resetGesture(); return }

        if count == 0 {
            // All fingers lifted — decide whether this was a valid tap.
            if touchStart > 0 {
                let elapsed = CFAbsoluteTimeGetCurrent() - touchStart
                // Accept the exact count, plus one extra to tolerate a palm or
                // thumb grazing the pad during a 3-/4-finger tap.
                let countOK = maxFingers == s.fingers
                    || (s.fingers >= 3 && maxFingers == s.fingers + 1)
                let hit = countOK && elapsed <= s.maxTapDuration && !moved
                if debug {
                    NSLog("MiddleClick tap: max=%d needed=%d elapsed=%.3fs moved=%@ -> %@",
                          maxFingers, s.fingers, elapsed, moved ? "Y" : "N",
                          hit ? "FIRE" : "skip")
                }
                resetGesture()
                if hit {
                    DispatchQueue.main.async { GestureDetector.emitMiddleClick() }
                }
            }
            return
        }

        // Average finger position for movement tracking.
        var avgX: Float = 0, avgY: Float = 0
        if let f = fingers {
            for i in 0..<count {
                avgX += f[i].normalized.position.x
                avgY += f[i].normalized.position.y
            }
            avgX /= Float(count)
            avgY /= Float(count)
        }

        if touchStart == 0 {
            // First contact of the gesture.
            touchStart = CFAbsoluteTimeGetCurrent()
            maxFingers = count
            startX = avgX
            startY = avgY
            moved = false
        } else if count > maxFingers {
            // A new finger just landed. The centroid shifts because we're now
            // averaging more contacts, NOT because fingers moved — so re-baseline
            // instead of counting it as movement.
            maxFingers = count
            startX = avgX
            startY = avgY
        } else if count == maxFingers {
            // Fingers stable at their peak — movement here is real.
            let dx = avgX - startX, dy = avgY - startY
            if (dx * dx + dy * dy).squareRoot() > s.maxMovement { moved = true }
        }
        // count < maxFingers: fingers are lifting off; ignore for movement.
    }

    // MARK: Event synthesis

    static func emitMiddleClick() {
        let loc = CGEvent(source: nil)?.location ?? .zero
        let src = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(mouseEventSource: src, mouseType: .otherMouseDown,
                           mouseCursorPosition: loc, mouseButton: .center)
        let up = CGEvent(mouseEventSource: src, mouseType: .otherMouseUp,
                         mouseCursorPosition: loc, mouseButton: .center)
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}

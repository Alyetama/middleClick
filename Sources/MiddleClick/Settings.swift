import Foundation

/// Persisted user preferences (UserDefaults-backed).
final class Settings {
    static let shared = Settings()

    private let d = UserDefaults.standard

    private enum Keys {
        static let enabled = "enabled"
        static let fingers = "fingers"
        static let sensitivity = "sensitivity"
    }

    private init() {
        d.register(defaults: [
            Keys.enabled: true,
            Keys.fingers: 3,
            Keys.sensitivity: 0.7,
        ])
    }

    var enabled: Bool {
        get { d.bool(forKey: Keys.enabled) }
        set { d.set(newValue, forKey: Keys.enabled) }
    }

    /// Number of fingers required for the tap (2, 3, or 4).
    var fingers: Int {
        get { max(2, min(4, d.integer(forKey: Keys.fingers))) }
        set { d.set(newValue, forKey: Keys.fingers) }
    }

    /// 0.0 = strict (fewer accidental triggers) ... 1.0 = lenient.
    var sensitivity: Double {
        get { d.double(forKey: Keys.sensitivity) }
        set { d.set(min(1, max(0, newValue)), forKey: Keys.sensitivity) }
    }

    // MARK: Derived tuning

    /// Max time (seconds) fingers may rest before the tap is considered a
    /// hold/scroll rather than a tap. Fingers often land and lift staggered,
    /// so this window is generous.
    var maxTapDuration: Double {
        0.30 + sensitivity * 0.90   // 0.30s ... 1.20s
    }

    /// Max normalized finger travel (0..1) allowed during the tap before it
    /// is treated as a swipe and ignored.
    var maxMovement: Float {
        Float(0.06 + sensitivity * 0.16) // 0.06 ... 0.22
    }
}

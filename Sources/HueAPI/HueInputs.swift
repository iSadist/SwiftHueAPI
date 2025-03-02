//
//  HueInputs.swift
//
//  Created by Jan Svensson on 2025-02-24.
//

import UIKit

public class Bridge {
    public var username: String?
    public var address: String?

    public init(username: String?, address: String?) {
        self.username = username
        self.address = address
    }
}

public class Light {
    public var lightID: String?
    public var scheduleID: String?

    public init(lightID: String? = nil, scheduleID: String? = nil) {
        self.lightID = lightID
        self.scheduleID = scheduleID
    }
}

extension Light: Hashable {
    public static func == (lhs: Light, rhs: Light) -> Bool {
        lhs.lightID == rhs.lightID
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(lightID)
    }
}

public class LightColor {
    public var hue: Float
    public var saturation: Float
    public var brightness: Float
    public var alpha: Float

    public init(hue: Float, saturation: Float, brightness: Float, alpha: Float) {
        self.hue = hue
        self.saturation = saturation
        self.brightness = brightness
        self.alpha = alpha
    }

    /// Returns the respective UIColor
    /// - Returns: UIColor
    public func toUIColor() -> UIColor {
        UIColor(hue: CGFloat(hue),
                       saturation: CGFloat(saturation),
                       brightness: CGFloat(brightness),
                       alpha: CGFloat(alpha))
    }

    /// Converts the values to the HueAPI interpretation
    /// - Returns: Hue, Saturation and Brightness
    public func toHueValues() -> (CGFloat, CGFloat, CGFloat) {
        var tempHue = CGFloat(hue)
        var tempSat = CGFloat(saturation)
        var tempBri = CGFloat(brightness)
        
        // Convert to Hue API values
        tempHue *= 65535
        tempSat *= 254
        tempBri *= 254
        
        return (tempHue, tempSat, tempBri)
    }
}

public class ReminderItem {
    public var name: String?
    public var light: Set<Light>
    public var active: Bool
    public var alert: AlertStyle
    public var author: String?
    public var time: Date?
    public var bridge: Bridge?
    public var alertStyle: String?
    public var color: LightColor?

    public init(name: String? = nil,
                light: Set<Light>,
                active: Bool,
                alert: AlertStyle,
                author: String? = nil,
                time: Date? = nil,
                bridge: Bridge? = nil,
                alertStyle: String? = nil,
                color: LightColor? = nil) {
        self.name = name
        self.light = light
        self.active = active
        self.alert = alert
        self.author = author
        self.time = time
        self.bridge = bridge
        self.alertStyle = alertStyle
        self.color = color
    }

    /// Get the alert style
    /// - Returns: The alert style
    public func getAlertStyle() -> AlertStyle? {
        guard let alertStyle = alertStyle else { return nil }
        return AlertStyle(rawValue: alertStyle)
    }
}

public enum HueURLError: Error {
    case invalid
}

public enum AlertStyle: String, CaseIterable, Identifiable {
    case color
    case select
    case lselect
    case colorloop
    public var id: Self { self }

    public var alertTitle: String {
        switch self {
        case .color: return NSLocalizedString("ALERT-COLOR", comment: "")
        case .select: return NSLocalizedString("ALERT-BLINK-ONCE", comment: "")
        case .lselect: return NSLocalizedString("ALERT-BLINK", comment: "")
        case .colorloop: return NSLocalizedString("ALERT-COLORSWEEP", comment: "")
        }
    }
}

//
//  ResponseStructs.swift
//
//  Created by Jan Svensson on 2025-02-24.
//

import Foundation
import SwiftUI

public typealias JSONValues = [String: HueLightResponse?]
public typealias JSONGroups = [String: HueGroupResponse?]

@available(iOS 13.0, *)
public struct HueLightInfo: Comparable, Identifiable, Hashable {
    public static func < (lhs: HueLightInfo, rhs: HueLightInfo) -> Bool {
        lhs.name < rhs.name
    }

    public var id: String
    public var name: String
    public var type: String?
    public var on: Bool
    public var color: Color
    public var brightness: Int

    public init(id: String, name: String, on: Bool, color: Color, brightness: Int) {
        self.id = id
        self.name = name
        self.on = on
        self.color = color
        self.brightness = brightness
    }

    public init?(key: String, value: HueLightResponse?) {
        guard let value = value, let state = value.state else {
            return nil
        }

        var color: Color!

        if let hue = state.hue, let sat = state.sat {
            color = Color(hue: Double(hue) / 65535,
                          saturation: Double(sat) / 255,
                          brightness: 1) // Always set to max brightness
        } else {
            if let ct = state.ct {
                color = Color(UIColor(mirek: ct))
            } else {
                color = Color.white
            }
        }

        id = key
        name = value.name ?? "Unknown name"
        type = value.type
        on = value.state?.on ?? false
        self.color = color
        brightness = value.state?.bri ?? 0
    }
}

/// Data struct for the response from the Hue API for /groups call.
public struct HueGroups: Comparable, Identifiable, Hashable {
    public var id: String
    public var lights: [String]
    public var name: String
    public var type: String
    public var modelid: String
    public var uniqueid: String
    public var `class`: String

    public static func < (lhs: HueGroups, rhs: HueGroups) -> Bool {
        lhs.name < rhs.name
    }

    public init?(key: String, value: HueGroupResponse?) {
        guard let value = value else {
            return nil
        }

        id = key
        lights = value.lights ?? []
        name = value.name ?? ""
        type = value.type ?? ""
        modelid = value.modelid ?? ""
        uniqueid = value.uniqueid ?? ""
        self.class = value.class ?? ""
    }

    /// Inits a mocked `Hue Group` response, typically used in preview or mock build.
    /// - Parameters:
    ///   - key: The key
    ///   - lights: The selected light ids
    ///   - name: The name of the groupd
    ///   - type: The type of the group
    public init(key: String, lights: [String], name: String, type: String) {
        id = key
        self.lights = lights
        self.name = name
        self.type = type
        modelid = "123"
        uniqueid = "zz112323x21"
        self.class = ""
    }
}

public struct HueGroupResponse: Decodable {
    public var name: String?
    public var lights: [String]?
    public var type: String?
    public var `class`: String?
    public var modelid: String?
    public var uniqueid: String?
}

public struct HueLightResponse: Decodable {
    public var state: HueLightState?
    public var type: String?
    public var name: String?
    public var modelid: String?
    public var manufacturername: String?
    public var productname: String?
    public var uniqueid: String?
    public var swversion: String?
}

public struct HueLightState: Decodable {
    public var on: Bool?
    public var bri: Int?
    public var hue: Int?
    public var sat: Int?
    public var effect: String?
    public var xy: [Double]?
    public var ct: Int?
    public var alert: String?
    public var colormode: String?
    public var mode: String?
    public var reachable: Bool?
}

public struct HueSchedulesResponse: Decodable {
    public var success: HueScheduleSuccess?
    public var error: HueScheduleError?
}

public struct HueSchedulesDeteleResponse: Decodable {
    public var success: String?
    public var error: HueScheduleError?
}

public struct HueScheduleSuccess: Decodable {
    public var id: String
}

public struct HueScheduleError: Decodable {
    public var type: Int
    public var address: String
    public var description: String
}

public typealias ScheduleValues = [String: HueSchedule?]

public struct HueSchedule: Decodable {
    public var name: String?
    public var description: String?
    public var command: HueCommand?
    public var localtime: String?
    public var created: String?
    public var status: String?
    public var autodelete: Bool?
    public var recycle: Bool?

    public func isScheduleFromThisApplication() -> Bool {
        guard let descriptionBody = description else {
            return false
        }

        let decoder = JSONDecoder()
        if let description = try? decoder.decode(HueReminderDescriptionBody.self,
                                                 from: descriptionBody.data(using: .utf8)!) {
            return description.type == appUniqueIdentifier
        }
        return false
    }

    public func getAuthor() -> String? {
        guard let descriptionBody = description else {
            return nil
        }

        let decoder = JSONDecoder()
        if let description = try? decoder.decode(HueReminderDescriptionBody.self,
                                                 from: descriptionBody.data(using: .utf8)!) {
            return description.author
        }

        return nil
    }

    public func getEncodedColor() -> (Float, Float) {
        guard let descriptionBody = description else {
            return (0, 0)
        }

        let decoder = JSONDecoder()
        if let description = try? decoder.decode(HueReminderDescriptionBody.self,
                                                 from: descriptionBody.data(using: .utf8)!),
           let hue = description.hue, let sat = description.sat {
            return (Float(hue), Float(sat))
        }

        return (0, 0)
    }

    public func isColorReminder() -> Bool {
        command?.body?.alert == nil
    }
}

public struct HueCommand: Decodable {
    public var address: String?
    public var body: HueCommandBody?
    public var method: String?
}

public struct HueCommandBody: Decodable {
    // The command can be of two kinds. One for color and the other for alert.
    // The two styles have different fields.

    // The color style.
    // These will be nil when command is alert style.
    public var bri: Int?
    public var on: Bool?
    public var sat: Int?
    public var hue: Int?

    // The alert style.
    // This field is empty when color style.
    public var alert: String?
}

public struct HueConfig: Decodable {
    public var name: String
    // Lots of more fields available
}

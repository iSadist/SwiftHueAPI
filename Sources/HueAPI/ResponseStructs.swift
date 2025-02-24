//
//  ResponseStructs.swift
//
//  Created by Jan Svensson on 2025-02-24.
//

import Foundation
import SwiftUI

typealias JSONValues = [String: HueLightResponse?]
typealias JSONGroups = [String: HueGroupResponse?]

@available(iOS 13.0, *)
struct HueLightInfo: Comparable, Identifiable, Hashable {
    static func < (lhs: HueLightInfo, rhs: HueLightInfo) -> Bool {
        lhs.name < rhs.name
    }

    var id: String
    var name: String
    var type: String?
    var on: Bool
    var color: Color
    var brightness: Int

    init(id: String, name: String, on: Bool, color: Color, brightness: Int) {
        self.id = id
        self.name = name
        self.on = on
        self.color = color
        self.brightness = brightness
    }

    init?(key: String, value: HueLightResponse?) {
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
struct HueGroups: Comparable, Identifiable, Hashable {
    var id: String
    var lights: [String]
    var name: String
    var type: String
    var modelid: String
    var uniqueid: String
    var `class`: String

    static func < (lhs: HueGroups, rhs: HueGroups) -> Bool {
        lhs.name < rhs.name
    }

    init?(key: String, value: HueGroupResponse?) {
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
    init(key: String, lights: [String], name: String, type: String) {
        id = key
        self.lights = lights
        self.name = name
        self.type = type
        modelid = "123"
        uniqueid = "zz112323x21"
        self.class = ""
    }
}

struct HueGroupResponse: Decodable {
    var name: String?
    var lights: [String]?
    var type: String?
    var `class`: String?
    var modelid: String?
    var uniqueid: String?
}

struct HueLightResponse: Decodable {
    var state: HueLightState?
    var type: String?
    var name: String?
    var modelid: String?
    var manufacturername: String?
    var productname: String?
    var uniqueid: String?
    var swversion: String?
}

struct HueLightState: Decodable {
    var on: Bool?
    var bri: Int?
    var hue: Int?
    var sat: Int?
    var effect: String?
    var xy: [Double]?
    var ct: Int?
    var alert: String?
    var colormode: String?
    var mode: String?
    var reachable: Bool?
}

struct HueSchedulesResponse: Decodable {
    var success: HueScheduleSuccess?
    var error: HueScheduleError?
}

struct HueSchedulesDeteleResponse: Decodable {
    var success: String?
    var error: HueScheduleError?
}

struct HueScheduleSuccess: Decodable {
    var id: String
}

struct HueScheduleError: Decodable {
    var type: Int
    var address: String
    var description: String
}

typealias ScheduleValues = [String: HueSchedule?]

struct HueSchedule: Decodable {
    var name: String?
    var description: String?
    var command: HueCommand?
    var localtime: String?
    var created: String?
    var status: String?
    var autodelete: Bool?
    var recycle: Bool?

    public func isScheduleFromThisApplication() -> Bool {
        guard let descriptionBody = description else {
            return false
        }

        let decoder = JSONDecoder()
        if let description = try? decoder.decode(HueReminderDescriptionBody.self,
                                                 from: descriptionBody.data(using: .utf8)!) {
            return description.type == HueAPI.appUniqueIdentifier
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

struct HueCommand: Decodable {
    var address: String?
    var body: HueCommandBody?
    var method: String?
}

struct HueCommandBody: Decodable {
    // The command can be of two kinds. One for color and the other for alert.
    // The two styles have different fields.

    // The color style.
    // These will be nil when command is alert style.
    var bri: Int?
    var on: Bool?
    var sat: Int?
    var hue: Int?

    // The alert style.
    // This field is empty when color style.
    var alert: String?
}

struct HueConfig: Decodable {
    var name: String
    // Lots of more fields available
}

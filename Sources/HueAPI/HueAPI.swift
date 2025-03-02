// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import UIKit
import SwiftUI

// TODO: Make this settable
let appUniqueIdentifier = "LF1.0"

public class HueAPI {
    static let appUniqueIdentifier = "LF1.0"

    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    /// Find bridges through the discovery API. Might become depreciated over MDNSBrowser.
    /// - Returns: The request
    public static func findBridges() -> URLRequest {
        guard let url = URL(string: "https://discovery.meethue.com") else {
            fatalError("invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return request
    }

    public static func connect(to ipaddress: String) -> URLRequest {
        guard let url = URL(string: "http://\(ipaddress)/api") else { fatalError("received an invalid ipaddress") }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let parameterDictionary = ["devicetype": "huereminders"]
        let httpBody = try! JSONSerialization.data(withJSONObject: parameterDictionary)
        request.httpBody = httpBody
        return request
    }

    @available(iOS 14.0, *)
    @available(iOSApplicationExtension 14.0, *)
    public static func setLight(color: Color, bridge: Bridge, lightID: String) -> URLRequest? {
        guard let ip = bridge.address, let username = bridge.username else { return nil }
        guard let url = URL(string: "http://\(ip)/api/\(username)/lights/\(lightID)/state") else { return nil }
        var request = URLRequest(url: url)
        guard let cgColor = color.cgColor else { return nil }

        let uiColor = UIColor(cgColor: cgColor)
        let (hue, sat, bri, _) = uiColor.getHueValues()

        let parameterDictionary = [
            "on": true,
            "hue": Int(hue * 65535),
            "sat": Int(sat * 254),
            "bri": Int(bri * 254)
        ] as [String: Any]
        let httpBody = try! JSONSerialization.data(withJSONObject: parameterDictionary)

        request.httpBody = httpBody
        request.httpMethod = "PUT"

        return request
    }

    public static func getLights(bridge: Bridge) throws -> URLRequest {
        guard let ip = bridge.address, let id = bridge.username else { fatalError("Missing ip or username") }
        guard let url = URL(string: "http://\(ip)/api/\(id)/lights") else { throw HueURLError.invalid }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return request
    }

    /// Get the groups from the Hue bridge.
    /// - Parameter bridge: The Hue bridge
    /// - Returns: The request
    public static func getGroups(bridge: Bridge) throws -> URLRequest {
        guard let ip = bridge.address, let id = bridge.username else { fatalError("Missing ip or username") }
        guard let url = URL(string: "http://\(ip)/api/\(id)/groups") else { throw HueURLError.invalid }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return request
    }

    @available(iOS 13.0, *)
    public static func toggleOnState(for light: HueLightInfo, _ bridge: Bridge) {
        guard let ip = bridge.address, let username = bridge.username else { return }
        guard let url = URL(string: "http://\(ip)/api/\(username)/lights/\(light.id)/state") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"

        let parameterDictionary = ["on": !light.on]
        let httpBody = try! JSONSerialization.data(withJSONObject: parameterDictionary)
        request.httpBody = httpBody

        let task = URLSession.shared.dataTask(with: request)
        task.resume()
    }

    public static func toggleActive(for reminder: ReminderItem, _ bridge: Bridge) {
        for light in reminder.light {
            guard let ip = bridge.address, let username = bridge.username else { fatalError("Missing ip or username") }
            guard let scheduleID = light.scheduleID else { fatalError("Missing schedule ID on Reminder") }
            guard let url = URL(string: "http://\(ip)/api/\(username)/schedules/\(scheduleID)/") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            
            let parameterDictionary = ["status": reminder.active ? "enabled" : "disabled"]
            let httpBody = try! JSONSerialization.data(withJSONObject: parameterDictionary)
            request.httpBody = httpBody
            
            let task = URLSession.shared.dataTask(with: request)
            task.resume()
        }
    }

    static private func createDescriptionBody(author: String?, hue: Float?, sat: Float?) -> String? {
        let descriptionBody = HueReminderDescriptionBody(author: author, hue: hue, sat: sat)
        let encoder = JSONEncoder()
        var descriptionBodyString: String?
        if let encodedDescriptionBody = try? encoder.encode(descriptionBody) {
            descriptionBodyString = String(data: encodedDescriptionBody, encoding: .utf8)
        }

        return descriptionBodyString
    }

    /// Creates an Alert request
    /// - Parameters:
    ///   - bridge: the hue bridge
    ///   - light: the light to receive an alert request
    ///   - style: the alert style
    /// - Returns: the URL request
    public static func alert(on bridge: Bridge, light: Light, style: AlertStyle = .lselect) throws -> URLRequest {
        let urlString = try HueAPI.makeAlertURLString(on: bridge, light: light, style: style)
        guard let url = URL(string: urlString) else {
            throw HueURLError.invalid
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"

        let body: [String: Any] = ["alert": "lselect"]
        let httpBody = try? JSONSerialization.data(withJSONObject: body)

        request.httpBody = httpBody

        return request
    }

    /// Creates a URL string for an alert request
    /// - Parameters:
    ///   - bridge: the hue bridge
    ///   - light: the light to receive an alert request
    ///   - style: the alert style
    /// - Returns: the URL string
    public static func makeAlertURLString(on bridge: Bridge, light: Light, style: AlertStyle) throws -> String {
        guard let ip = bridge.address,
              let id = bridge.username,
              let lightID = light.lightID else {
            throw HueURLError.invalid
        }

        let urlString = makeAlertURLString(ip, id, lightID)

        return urlString
    }

    /// Creates a URL string for an alert request
    /// - Parameters:
    ///   - address: the hue bridge address
    ///   - username: the hue bridge username
    ///   - lightID: the light to receive an alert request
    /// - Returns: the URL string
    public static func makeAlertURLString(_ address: String, _ username: String, _ lightID: String) -> String {
        "http://\(address)/api/\(username)/lights/\(lightID)/state"
    }

    public static func createSchedule(on bridge: Bridge,
                                   reminder: ReminderItem,
                                   light: Light,
                                   style: AlertStyle = .color) -> URLRequest {
        guard let color = reminder.color else { fatalError("Missing color for reminder") }
        guard let ip = bridge.address, let id = bridge.username else { fatalError("Missing ip or username") }
        guard let time = reminder.time else { fatalError("Missing time on reminder") }
        guard let lightID = light.lightID else { fatalError("Missing light id")}
        let urlString = "http://\(ip)/api/\(id)/schedules"
        guard let url = URL(string: urlString) else { fatalError("Not a valid URL") }
        var request = URLRequest(url: url)

        let dateString = dateFormatter.string(from: time)
        let (hue, sat, bri) = color.toHueValues()

        var body: [String: Any] = [:]

        switch style {
        case .color:
            body = ["on": true, "hue": Int(hue), "sat": Int(sat), "bri": Int(bri)]
        case .colorloop:
            body = ["on": true, "effect": "colorloop"]
        case .select:
            body = ["alert": "select"]
        case .lselect:
            body = ["alert": "lselect"]
        }

        let descriptionBody = createDescriptionBody(author: reminder.author, hue: Float(hue), sat: Float(sat))
        let command = ["address": "/api/\(id)/lights/\(lightID)/state", "method": "PUT", "body": body] as [String: Any]
        let parameters = [
            "name": reminder.name ?? NSLocalizedString("UNKNOWN", comment: ""),
            "description": descriptionBody ?? "",
            "command": command,
            "autodelete": true,
            "localtime": dateString
            ] as [String: Any]

        let httpBody = try! JSONSerialization.data(withJSONObject: parameters)
        request.httpBody = httpBody
        request.httpMethod = "POST"
        return request
    }

    public static func findSchedules(_ bridge: Bridge) throws -> URLRequest {
        guard let ip = bridge.address,
              let id = bridge.username,
              let url = URL(string: "http://\(ip)/api/\(id)/schedules") else {
            throw HueURLError.invalid
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return request
    }

    public static func updateSchedule(reminder: ReminderItem, light: Light) -> URLRequest? {
        guard let bridge = reminder.bridge else { return nil }
        guard let color = reminder.color else { fatalError("Missing color for reminder") }
        guard let ip = bridge.address, let id = bridge.username else { fatalError("Missing ip or username") }
        guard let time = reminder.time else { fatalError("Missing time on reminder") }
        guard let lightID = light.lightID else { fatalError("Missing light id")}
        guard let scheduleID = light.scheduleID else { fatalError("Missing schedule ID") }
        guard let url = URL(string: "http://\(ip)/api/\(id)/schedules/\(scheduleID)") else {
            fatalError("Not a valid URL")
        }
        var request = URLRequest(url: url)

        let dateString = dateFormatter.string(from: time)
        let (hue, sat, bri) = color.toHueValues()
        let descriptionBody = createDescriptionBody(author: reminder.author, hue: Float(hue), sat: Float(sat))

        let style: AlertStyle = reminder.getAlertStyle() ?? .select
        var body: [String: Any]

        if style == .color {
            body = ["on": true, "hue": Int(hue), "sat": Int(sat), "bri": Int(bri)] as [String: Any]
        } else {
            body = ["alert": style.rawValue]
        }

        let command = ["address": "/api/\(id)/lights/\(lightID)/state", "method": "PUT", "body": body] as [String: Any]
        let parameters = [
            "name": reminder.name ?? NSLocalizedString("UNKNOWN", comment: ""),
            "description": descriptionBody ?? "",
            "command": command,
            "autodelete": true,
            "localtime": dateString
            ] as [String: Any]

        let httpBody = try! JSONSerialization.data(withJSONObject: parameters)
        request.httpBody = httpBody
        request.httpMethod = "PUT"
        return request
    }

    public static func deleteSchedule(on bridge: Bridge, reminder: ReminderItem) -> [URLRequest] {
        var requests = [URLRequest]()
        for light in reminder.light {
            guard let ip = bridge.address, let id = bridge.username else { fatalError("Missing ip or username") }
            guard let scheduleID = light.scheduleID else { continue }
            guard let url = URL(string: "http://\(ip)/api/\(id)/schedules/\(scheduleID)") else {
                continue
            }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            requests.append(request)
        }
        return requests
    }

    public static func getConfiguration(bridge: Bridge) throws -> URLRequest {
        guard let ip = bridge.address, let id = bridge.username else { fatalError("Missing ip or username") }
        guard let url = URL(string: "http://\(ip)/api/\(id)/config") else { throw HueURLError.invalid }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return request
    }
}


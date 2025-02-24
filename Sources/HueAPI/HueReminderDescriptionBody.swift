//
//  HueReminderDescriptionBody.swift
//
//  Created by Jan Svensson on 2025-02-24.
//

import Foundation

public class HueReminderDescriptionBody: Codable {
    public var type = appUniqueIdentifier
    public var author: String?
    public var hue: Int?
    public var sat: Int?

    public init(author: String?, hue: Float?, sat: Float?) {
        self.author = author?.cap(first: 10)

        if let hue = hue, let sat = sat {
            self.hue = Int(hue)
            self.sat = Int(sat)
        }
    }

    // The body needs to be short, therefore CodingKeys and init(from decoder: Decoder) are not used

    enum CodingKeys: CodingKey {
        case t
        case a
        case h
        case s
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .t)
        self.author = try container.decodeIfPresent(String.self, forKey: .a)
        self.hue = try container.decodeIfPresent(Int.self, forKey: .h)
        self.sat = try container.decodeIfPresent(Int.self, forKey: .s)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .t)
        try container.encodeIfPresent(author, forKey: .a)
        try container.encodeIfPresent(hue, forKey: .h)
        try container.encodeIfPresent(sat, forKey: .s)
    }
}

extension String {
    fileprivate func cap(first: Int) -> String {
        let endIndex = index(startIndex, offsetBy: min(first - 1, count - 1))
        return String(self[startIndex...endIndex])
    }
}

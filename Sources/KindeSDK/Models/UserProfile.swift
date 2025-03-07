//
// UserProfile.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct UserProfile: Codable, JSONEncodable, Hashable {

    public let id: String
    public let providedId: String?
    public let name: String?
    public let givenName: String?
    public let familyName: String?
    public let updatedAt: Int
    public let email: String?

    public init(id: String, providedId: String? = nil, name: String? = nil, givenName: String? = nil, familyName: String? = nil, updatedAt: Int, email: String? = nil) {
        self.id = id
        self.providedId = providedId
        self.name = name
        self.givenName = givenName
        self.familyName = familyName
        self.updatedAt = updatedAt
        self.email = email
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case providedId = "provided_id"
        case name
        case givenName = "given_name"
        case familyName = "family_name"
        case updatedAt = "updated_at"
        case email
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(providedId, forKey: .providedId)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(givenName, forKey: .givenName)
        try container.encodeIfPresent(familyName, forKey: .familyName)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(email, forKey: .email)
    }
}


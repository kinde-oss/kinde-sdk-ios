
import Foundation

extension String {
    public var parsedJWT: [String: Any?] {
        let tokenString = self
        var params: [String: Any?] = [:]
        do {
            let data = try decode(jwtToken: tokenString)
            params = data
        } catch {
            preconditionFailure("\(error.localizedDescription)")
        }
        return params
    }
    
    func decode(jwtToken jwt: String) throws -> [String: Any] {
        enum DecodeErrors: Error {
            case badToken
            case other
        }

        func base64Decode(_ base64: String) throws -> Data {
            let base64 = base64
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            let padded = base64.padding(toLength: ((base64.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
            guard let decoded = Data(base64Encoded: padded) else {
                throw DecodeErrors.badToken
            }
            return decoded
        }

        func decodeJWTPart(_ value: String) throws -> [String: Any] {
            let bodyData = try base64Decode(value)
            let json = try JSONSerialization.jsonObject(with: bodyData, options: [])
            guard let payload = json as? [String: Any] else {
                throw DecodeErrors.other
            }
            return payload
        }
        let segments = jwt.components(separatedBy: ".")
        if segments.count > 2 {
            return try decodeJWTPart(segments[1])
        } else {
            return [:]
        }
    }
}

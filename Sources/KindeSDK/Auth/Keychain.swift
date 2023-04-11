
import Foundation

public class Keychain {
    
    private static func addQuery(service: String, password: Data) -> [String: Any] {
        guard let encodedIdentifier: Data = service.data(using: String.Encoding.utf8) else {
            return [:]
        }
        return [kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: Bundle.main.bundleIdentifier ?? "KeychainWrapper",
                kSecAttrSynchronizable as String: false,
                kSecAttrGeneric as String: encodedIdentifier,
                kSecAttrAccount as String: encodedIdentifier,
                kSecValueData as String: password,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly] as [String : Any]
    }

    private static func retrieveQuery(service: String) -> [String: Any] {
        guard let encodedIdentifier: Data = service.data(using: String.Encoding.utf8) else {
            return [:]
        }
        return [kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: Bundle.main.bundleIdentifier ?? "KeychainWrapper",
                kSecAttrSynchronizable as String: false,
                kSecAttrGeneric as String: encodedIdentifier,
                kSecAttrAccount as String: encodedIdentifier,
                kSecMatchLimit as String: kSecMatchLimitOne,
                kSecReturnData as String: true] as [String : Any]
    }
    
    private static func searchQuery(service: String) -> [String: Any] {
        guard let encodedIdentifier: Data = service.data(using: String.Encoding.utf8) else {
            return [:]
        }
        return [kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: Bundle.main.bundleIdentifier ?? "KeychainWrapper",
                kSecAttrSynchronizable as String: false,
                kSecAttrGeneric as String: encodedIdentifier,
                kSecAttrAccount as String: encodedIdentifier] as [String : Any]
    }

    private static func updateQuery(password: Data) -> CFDictionary {
        [kSecValueData as String: password,
         kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly ] as [String : Any] as CFDictionary
    }

    private static func update(service: String, value: String) -> OSStatus {
        update(service: service, value: value.data(using: .utf8)!)
    }
    
    @discardableResult
    static func update(service: String, value: Data) -> OSStatus {
        var keychainQueryDictionary = addQuery(service: service, password: value)
        keychainQueryDictionary[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
        
        let status: OSStatus = SecItemAdd(keychainQueryDictionary as CFDictionary, nil)
        
        if status == errSecSuccess {
            return errSecSuccess
        } else if status == errSecDuplicateItem {
            return update(service: service, value: value)
        } else {
            return status
        }
    }
    
    @discardableResult
    static func delete(service: String) -> OSStatus {
        let keychainQueryDictionary = searchQuery(service: service) as CFDictionary
        let status: OSStatus = SecItemDelete(keychainQueryDictionary)

        return status
    }
    
    static func set(state: NSCoding?, service: String) -> Bool {
        if let state = state {
            let data = NSKeyedArchiver.archivedData(withRootObject: state)
            return update(service: service, value: data) == errSecSuccess
        } else {
            return delete(service: service) == errSecSuccess
        }
    }
    
    static func get(_ service: String) -> NSCoding? {
        var result: AnyObject?

        let status = SecItemCopyMatching(retrieveQuery(service: service) as CFDictionary, &result)
        
        if status == noErr,
           let data = result as? Data {
           return NSKeyedUnarchiver.unarchiveObject(with: data) as? NSCoding
        }
        return nil
    }
}

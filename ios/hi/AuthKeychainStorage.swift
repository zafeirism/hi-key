import Foundation
import Security
import Supabase

struct AuthKeychainStorage: AuthLocalStorage {
    private let appGroupID = "group.ai.hi-key"
    
    func store(key: String, value: Data) throws {
        print("Storing \(key) in keychain...")
        // Delete any existing item first
        try remove(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: appGroupID,
            kSecValueData as String: value,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemAdd(query as CFDictionary, nil)
    }

    func retrieve(key: String) throws -> Data? {
        print("Trying to retrieve \(key) in keychain...")
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: appGroupID,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        let data = dataTypeRef as? Data
        return data
    }

    func remove(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: appGroupID
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

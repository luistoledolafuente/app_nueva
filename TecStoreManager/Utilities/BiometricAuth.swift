import Foundation
import LocalAuthentication
import Security

class BiometricAuth {
    static let shared = BiometricAuth()

    private let accountsKey = "com.tecstoremanager.credentials"

    var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    var biometryType: LABiometryType {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return ctx.biometryType
    }

    func saveCredentials(email: String, password: String) {
        let data = "\(email)::\(password)".data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: accountsKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func getCredentials() -> (email: String, password: String)? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: accountsKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let str = String(data: data, encoding: .utf8),
              let sep = str.firstIndex(of: ":") else { return nil }
        let emailEnd = str[..<sep]
        let pwdStart = str[sep...].dropFirst(2)
        return (String(emailEnd), String(pwdStart))
    }

    func clearCredentials() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: accountsKey
        ]
        SecItemDelete(query as CFDictionary)
    }

    func authenticate(reason: String = "Acceder a TecStoreManager") async -> Bool {
        return await withCheckedContinuation { continuation in
            let ctx = LAContext()
            ctx.localizedFallbackTitle = "Usar contraseña"
            ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}

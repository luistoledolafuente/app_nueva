import Foundation
import CoreData
import CryptoKit
import UIKit

#if canImport(FirebaseAuth)
import FirebaseAuth
import GoogleSignIn
#endif

// MARK: - Firebase Authentication Service
//
// INSTRUCCIONES PARA ACTIVAR FIREBASE:
// 1. Ve a https://console.firebase.google.com y crea un proyecto "TecStoreManager"
// 2. Registra una app iOS con el bundle ID de tu proyecto
// 3. Descarga GoogleService-Info.plist y agrégalo al proyecto Xcode
// 4. En Xcode: File → Add Package Dependencies → https://github.com/firebase/firebase-ios-sdk
// 5. Selecciona "FirebaseAuth"
// 6. En Xcode: File → Add Package Dependencies → https://github.com/google/GoogleSignIn-iOS
// 7. Abre AppDelegate.swift y descomenta las líneas marcadas con TODO: Firebase
// 8. Compila y ejecuta

class FirebaseAuthService {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.context) {
        self.context = context
    }

    #if canImport(FirebaseAuth)

    func login(email: String, password: String) async -> Result<Usuario, Error> {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let firebaseUser = result.user
            return obtenerOCrearUsuarioLocal(firebaseUser: firebaseUser, nombreCompleto: firebaseUser.displayName ?? email)
        } catch {
            return .failure(error)
        }
    }

    func register(email: String, password: String, nombreCompleto: String) async -> Result<Usuario, Error> {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = nombreCompleto
            try await changeRequest.commitChanges()
            return obtenerOCrearUsuarioLocal(firebaseUser: result.user, nombreCompleto: nombreCompleto)
        } catch {
            return .failure(error)
        }
    }

    func signInWithGoogle(presenting viewController: UIViewController) async -> Result<Usuario, Error> {
        do {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                return .failure(NSError(domain: "Auth", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Configuración de Firebase incompleta"]))
            }
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            guard let idToken = result.user.idToken?.tokenString else {
                return .failure(NSError(domain: "Auth", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Error al obtener token de Google"]))
            }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: result.user.accessToken.tokenString)
            let authResult = try await Auth.auth().signIn(with: credential)
            let firebaseUser = authResult.user
            return obtenerOCrearUsuarioLocal(firebaseUser: firebaseUser,
                                             nombreCompleto: firebaseUser.displayName ?? firebaseUser.email ?? "Usuario")
        } catch {
            return .failure(error)
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
        } catch {
            print("Error al cerrar sesión: \(error.localizedDescription)")
        }
    }

    func checkCurrentSession() -> Usuario? {
        guard let firebaseUser = Auth.auth().currentUser else { return nil }
        return buscarUsuarioLocal(uid: firebaseUser.uid)
    }

    func addAuthStateListener(handler: @escaping (Usuario?) -> Void) {
        Auth.auth().addStateDidChangeListener { _, firebaseUser in
            if let firebaseUser = firebaseUser {
                let usuario = self.buscarUsuarioLocal(uid: firebaseUser.uid)
                handler(usuario)
            } else {
                handler(nil)
            }
        }
    }

    private func obtenerOCrearUsuarioLocal(firebaseUser: FirebaseAuth.User, nombreCompleto: String) -> Result<Usuario, Error> {
        let request: NSFetchRequest<Usuario> = Usuario.fetchRequest()
        request.predicate = NSPredicate(format: "idUsuario == %@", firebaseUser.uid as NSString)

        if let existing = try? context.fetch(request).first {
            existing.nombreCompleto = nombreCompleto
            PersistenceController.shared.save()
            return .success(existing)
        }

        let usuario = Usuario(context: context)
        usuario.idUsuario      = UUID(uuidString: firebaseUser.uid) ?? UUID()
        usuario.nombreUsuario  = firebaseUser.email ?? ""
        usuario.password       = ""
        usuario.nombreCompleto = nombreCompleto
        usuario.estado         = true
        PersistenceController.shared.save()
        return .success(usuario)
    }

    private func buscarUsuarioLocal(uid: String) -> Usuario? {
        let request: NSFetchRequest<Usuario> = Usuario.fetchRequest()
        request.predicate = NSPredicate(format: "idUsuario == %@", uid)
        return (try? context.fetch(request))?.first
    }

    #else

    // MARK: - Fallback: Auth local sin Firebase

    private static func hashPassword(_ password: String) -> String {
        let digest = SHA256.hash(data: Data(password.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func login(email: String, password: String) async -> Result<Usuario, Error> {
        let request: NSFetchRequest<Usuario> = Usuario.fetchRequest()
        request.predicate = NSPredicate(
            format: "nombreUsuario == %@ AND password == %@",
            email, Self.hashPassword(password)
        )
        if let usuario = try? context.fetch(request).first {
            return .success(usuario)
        }
        return .failure(NSError(domain: "Auth", code: 401,
            userInfo: [NSLocalizedDescriptionKey: "Usuario o contraseña incorrectos"]))
    }

    func register(email: String, password: String, nombreCompleto: String) async -> Result<Usuario, Error> {
        let request: NSFetchRequest<Usuario> = Usuario.fetchRequest()
        request.predicate = NSPredicate(format: "nombreUsuario == %@", email)
        if (try? context.fetch(request).first) != nil {
            return .failure(NSError(domain: "Auth", code: 409,
                userInfo: [NSLocalizedDescriptionKey: "El usuario ya existe"]))
        }
        let usuario = Usuario(context: context)

        usuario.idUsuario      = UUID()
        usuario.nombreUsuario  = email
        usuario.password       = Self.hashPassword(password)
        usuario.nombreCompleto = nombreCompleto
        usuario.estado         = true
        PersistenceController.shared.save()
        return .success(usuario)
    }

    func signInWithGoogle(presenting viewController: UIViewController) async -> Result<Usuario, Error> {
        return .failure(NSError(domain: "Auth", code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Google Sign-In requiere Firebase SDK"]))
    }

    func logout() {}

    func checkCurrentSession() -> Usuario? { return nil }

    func addAuthStateListener(handler: @escaping (Usuario?) -> Void) {}

    #endif
}

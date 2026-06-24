import Foundation
import CoreData
import CryptoKit
import UIKit

class LocalAuthService {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.context) {
        self.context = context
    }

    static func hashPassword(_ password: String) -> String {
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

    func logout() {}

    func checkCurrentSession() -> Usuario? {
        let request: NSFetchRequest<Usuario> = Usuario.fetchRequest()
        return try? context.fetch(request).first
    }
}

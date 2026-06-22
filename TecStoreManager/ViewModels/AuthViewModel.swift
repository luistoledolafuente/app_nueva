import Foundation
import CoreData
import CryptoKit

class AuthViewModel: ObservableObject {
    
    @Published var usuarioActual: Usuario?
    @Published var estaLogueado: Bool   = false
    @Published var errorMessage: String = ""
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.context) {
        self.context = context
    }
    
    // MARK: - Login
    func login(nombreUsuario: String, password: String) -> Bool {
        guard Validators.isNotEmpty(nombreUsuario),
              Validators.isNotEmpty(password) else {
            errorMessage = "Usuario y contraseña son obligatorios"
            return false
        }
        
        let request: NSFetchRequest<Usuario> = Usuario.fetchRequest()
        request.predicate = NSPredicate(
            format: "nombreUsuario == %@ AND password == %@",
            nombreUsuario, Self.hashPassword(password)
        )

        if let usuario = try? context.fetch(request).first {
            usuarioActual = usuario
            estaLogueado  = true
            errorMessage  = ""
            return true
        } else {
            errorMessage = "Usuario o contraseña incorrectos"
            return false
        }
    }
    
    // MARK: - Registro
    func registrar(nombreUsuario: String, password: String, nombreCompleto: String) -> Bool {
        guard Validators.isNotEmpty(nombreUsuario),
              Validators.isNotEmpty(password),
              Validators.isNotEmpty(nombreCompleto) else {
            errorMessage = "Todos los campos son obligatorios"
            return false
        }
        
        let request: NSFetchRequest<Usuario> = Usuario.fetchRequest()
        request.predicate = NSPredicate(format: "nombreUsuario == %@", nombreUsuario)
        
        if (try? context.fetch(request).first) != nil {
            errorMessage = "El usuario ya existe"
            return false
        }
        
        let usuario = Usuario(context: context)
        usuario.idUsuario      = UUID()
        usuario.nombreUsuario  = nombreUsuario
        usuario.password       = Self.hashPassword(password)
        usuario.nombreCompleto = nombreCompleto
        usuario.estado         = true
        
        PersistenceController.shared.save()
        errorMessage = ""
        return true
    }
    
    // MARK: - Logout
    func logout() {
        usuarioActual = nil
        estaLogueado  = false
    }

    // MARK: - Hashing
    static func hashPassword(_ password: String) -> String {
        let digest = SHA256.hash(data: Data(password.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

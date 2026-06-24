import Foundation
import CoreData
import UIKit

@MainActor
class AuthViewModel: ObservableObject {

    @Published var usuarioActual: Usuario?
    @Published var estaLogueado: Bool = false
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false

    private let authService: LocalAuthService

    init(authService: LocalAuthService = LocalAuthService()) {
        self.authService = authService
        verificarSesion()
    }

    func verificarSesion() {
        if let usuario = authService.checkCurrentSession() {
            usuarioActual = usuario
            estaLogueado = true
        }
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = ""

        let result = await authService.login(email: email, password: password)
        switch result {
        case .success(let usuario):
            usuarioActual = usuario
            estaLogueado = true
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func register(email: String, password: String, nombreCompleto: String) async -> Bool {
        isLoading = true
        errorMessage = ""

        let result = await authService.register(email: email, password: password, nombreCompleto: nombreCompleto)
        isLoading = false
        switch result {
        case .success:
            errorMessage = ""
            return true
        case .failure(let error):
            errorMessage = error.localizedDescription
            return false
        }
    }

    func logout() {
        authService.logout()
        usuarioActual = nil
        estaLogueado = false
    }
}

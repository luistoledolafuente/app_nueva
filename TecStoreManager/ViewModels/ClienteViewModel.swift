import Foundation
import CoreData

class ClienteViewModel: ObservableObject {
    
    @Published var clientes: [Cliente]  = []
    @Published var errorMessage: String = ""
    @Published var searchText: String   = ""
    
    private let repository: ClienteRepository
    
    init(repository: ClienteRepository = ClienteRepository()) {
        self.repository = repository
        cargar()
    }
    
    // MARK: - Cargar
    func cargar() {
        clientes = repository.obtenerTodos()
    }
    
    // MARK: - Crear
    func crear(dni: String, nombres: String, apellidos: String, telefono: String, correo: String, direccion: String) -> Bool {
        if let error = Validators.validarCliente(
            nombres: nombres,
            apellidos: apellidos,
            dni: dni,
            correo: correo,
            telefono: telefono
        ) {
            errorMessage = error
            return false
        }
        
        repository.crear(
            dni: dni,
            nombres: nombres,
            apellidos: apellidos,
            telefono: telefono,
            correo: correo,
            direccion: direccion
        )
        cargar()
        errorMessage = ""
        return true
    }
    
    // MARK: - Actualizar
    func actualizar(_ cliente: Cliente, dni: String, nombres: String, apellidos: String, telefono: String, correo: String, direccion: String, estado: Bool) -> Bool {
        if let error = Validators.validarCliente(
            nombres: nombres,
            apellidos: apellidos,
            dni: dni,
            correo: correo,
            telefono: telefono
        ) {
            errorMessage = error
            return false
        }
        
        repository.actualizar(
            cliente,
            dni: dni,
            nombres: nombres,
            apellidos: apellidos,
            telefono: telefono,
            correo: correo,
            direccion: direccion,
            estado: estado
        )
        cargar()
        errorMessage = ""
        return true
    }
    
    // MARK: - Eliminar
    func eliminar(_ cliente: Cliente) {
        repository.eliminar(cliente)
        cargar()
    }
    
    // MARK: - Buscar por DNI
    func buscarPorDNI() {
        if searchText.isEmpty {
            cargar()
        } else {
            clientes = repository.buscarPorDNI(searchText)
        }
    }
    
    // MARK: - Buscar por nombre
    func buscarPorNombre() {
        if searchText.isEmpty {
            cargar()
        } else {
            clientes = repository.buscarPorNombre(searchText)
        }
    }
    
    // MARK: - Filtrar por estado
    func filtrarPorEstado(_ estado: Bool) {
        clientes = repository.filtrarPorEstado(estado)
    }
    
    // MARK: - Total clientes
    func totalClientes() -> Int {
        return repository.totalClientes()
    }
}

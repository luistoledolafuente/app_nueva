import CoreData

class ClienteRepository {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.context) {
        self.context = context
    }
    
    // MARK: - Crear
    func crear(dni: String, nombres: String, apellidos: String, telefono: String, correo: String, direccion: String) {
        let cliente = Cliente(context: context)
        cliente.idCliente  = UUID()
        cliente.dni        = dni
        cliente.nombres    = nombres
        cliente.apellidos  = apellidos
        cliente.telefono   = telefono
        cliente.correo     = correo
        cliente.direccion  = direccion
        cliente.estado     = true
        PersistenceController.shared.save()
    }
    
    // MARK: - Obtener todos
    func obtenerTodos() -> [Cliente] {
        let request: NSFetchRequest<Cliente> = Cliente.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "nombres", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Buscar por DNI
    func buscarPorDNI(_ dni: String) -> [Cliente] {
        let request: NSFetchRequest<Cliente> = Cliente.fetchRequest()
        request.predicate = NSPredicate(format: "dni CONTAINS[cd] %@", dni)
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Buscar por nombre
    func buscarPorNombre(_ nombre: String) -> [Cliente] {
        let request: NSFetchRequest<Cliente> = Cliente.fetchRequest()
        request.predicate = NSPredicate(format: "nombres CONTAINS[cd] %@ OR apellidos CONTAINS[cd] %@", nombre, nombre)
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Filtrar por estado
    func filtrarPorEstado(_ estado: Bool) -> [Cliente] {
        let request: NSFetchRequest<Cliente> = Cliente.fetchRequest()
        request.predicate = NSPredicate(format: "estado == %@", NSNumber(value: estado))
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Actualizar
    func actualizar(_ cliente: Cliente, dni: String, nombres: String, apellidos: String, telefono: String, correo: String, direccion: String, estado: Bool) {
        cliente.dni       = dni
        cliente.nombres   = nombres
        cliente.apellidos = apellidos
        cliente.telefono  = telefono
        cliente.correo    = correo
        cliente.direccion = direccion
        cliente.estado    = estado
        PersistenceController.shared.save()
    }
    
    // MARK: - Eliminar
    func eliminar(_ cliente: Cliente) {
        context.delete(cliente)
        PersistenceController.shared.save()
    }
    
    // MARK: - Total clientes
    func totalClientes() -> Int {
        let request: NSFetchRequest<Cliente> = Cliente.fetchRequest()
        return (try? context.count(for: request)) ?? 0
    }
}

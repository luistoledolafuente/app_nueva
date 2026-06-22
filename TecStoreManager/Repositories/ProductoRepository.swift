import CoreData

class ProductoRepository {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.context) {
        self.context = context
    }
    
    // MARK: - Crear
    func crear(codigo: String, nombre: String, categoria: String, precio: Double, stock: Int) {
        let producto = Producto(context: context)
        producto.idProducto    = UUID()
        producto.codigo        = codigo
        producto.nombre        = nombre
        producto.categoria     = categoria
        producto.precio        = precio
        producto.stock         = Int32(stock)
        producto.fechaRegistro = Date()
        producto.estado        = true
        PersistenceController.shared.save()
    }
    
    // MARK: - Obtener todos
    func obtenerTodos() -> [Producto] {
        let request: NSFetchRequest<Producto> = Producto.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "nombre", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Buscar por nombre
    func buscarPorNombre(_ nombre: String) -> [Producto] {
        let request: NSFetchRequest<Producto> = Producto.fetchRequest()
        request.predicate = NSPredicate(format: "nombre CONTAINS[cd] %@", nombre)
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Filtrar por categoria
    func filtrarPorCategoria(_ categoria: String) -> [Producto] {
        let request: NSFetchRequest<Producto> = Producto.fetchRequest()
        request.predicate = NSPredicate(format: "categoria == %@", categoria)
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Filtrar stock bajo
    func filtrarStockBajo(limite: Int = 5) -> [Producto] {
        let request: NSFetchRequest<Producto> = Producto.fetchRequest()
        request.predicate = NSPredicate(format: "stock <= %d", limite)
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Actualizar
    func actualizar(_ producto: Producto, codigo: String, nombre: String, categoria: String, precio: Double, stock: Int) {
        producto.codigo    = codigo
        producto.nombre    = nombre
        producto.categoria = categoria
        producto.precio    = precio
        producto.stock     = Int32(stock)
        PersistenceController.shared.save()
    }
    
    // MARK: - Eliminar
    func eliminar(_ producto: Producto) {
        context.delete(producto)
        PersistenceController.shared.save()
    }
    
    // MARK: - Producto menor stock
    func productoMenorStock() -> Producto? {
        let request: NSFetchRequest<Producto> = Producto.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "stock", ascending: true)]
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}

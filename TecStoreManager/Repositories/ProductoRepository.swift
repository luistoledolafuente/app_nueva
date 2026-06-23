import CoreData

class ProductoRepository {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.context) {
        self.context = context
    }
    
    // MARK: - Crear
    func crear(codigo: String, nombre: String, categoria: String, precio: Double, stock: Int, imagenPath: String? = nil) {
        let producto = Producto(context: context)
        producto.idProducto    = UUID()
        producto.codigo        = codigo
        producto.nombre        = nombre
        producto.categoria     = categoria
        producto.precio        = precio
        producto.stock         = Int32(stock)
        producto.fechaRegistro = Date()
        producto.estado        = true
        producto.imagenPath    = imagenPath
        PersistenceController.shared.save()
        if stock <= 5 {
            NotificationManager.shared.scheduleLowStockAlert(productName: nombre, stock: stock, codigo: codigo)
        }
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
    func actualizar(_ producto: Producto, codigo: String, nombre: String, categoria: String, precio: Double, stock: Int, imagenPath: String? = nil) {
        producto.codigo    = codigo
        producto.nombre    = nombre
        producto.categoria = categoria
        producto.precio    = precio
        producto.stock     = Int32(stock)
        if let img = imagenPath { producto.imagenPath = img }
        PersistenceController.shared.save()
        if stock <= 5 {
            NotificationManager.shared.scheduleLowStockAlert(productName: producto.nombre ?? "", stock: stock, codigo: producto.codigo ?? "")
        }
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
    
    // MARK: - Generar código de producto
    func generarCodigoProducto() -> String {
        let request: NSFetchRequest<Producto> = Producto.fetchRequest()
        request.predicate = NSPredicate(format: "codigo != nil")
        request.sortDescriptors = [NSSortDescriptor(key: "codigo", ascending: false)]
        request.fetchLimit = 1
        
        let ultimo = (try? context.fetch(request))?.first?.codigo ?? "PR-00000"
        let numero: Int
        if ultimo.hasPrefix("PR-") {
            numero = Int(ultimo.dropFirst(3)) ?? 0
        } else {
            numero = 0
        }
        return String(format: "PR-%05d", numero + 1)
    }
}

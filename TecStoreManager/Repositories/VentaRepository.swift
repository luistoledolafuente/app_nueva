import CoreData

class VentaRepository {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.context) {
        self.context = context
    }
    
    // MARK: - Crear
    func crear(cantidad: Int, precio: Double, cliente: Cliente, producto: Producto) {
        let subtotal = Double(cantidad) * precio
        let igv      = subtotal * AppConstants.igvRate
        let total    = subtotal + igv
        
        let venta = Venta(context: context)
        venta.idVenta    = UUID()
        venta.fechaVenta = Date()
        venta.cantidad   = Int32(cantidad)
        venta.precio     = precio
        venta.subtotal   = subtotal
        venta.igv        = igv
        venta.total      = total
        venta.cliente    = cliente
        venta.producto   = producto
        
        producto.stock -= Int32(cantidad)
        
        PersistenceController.shared.save()
    }
    
    // MARK: - Obtener todas
    func obtenerTodas() -> [Venta] {
        let request: NSFetchRequest<Venta> = Venta.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "fechaVenta", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Buscar por cliente
    func buscarPorCliente(_ nombre: String) -> [Venta] {
        let request: NSFetchRequest<Venta> = Venta.fetchRequest()
        request.predicate = NSPredicate(format: "cliente.nombres CONTAINS[cd] %@ OR cliente.apellidos CONTAINS[cd] %@", nombre, nombre)
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Buscar por fecha
    func buscarPorFecha(desde: Date, hasta: Date) -> [Venta] {
        let request: NSFetchRequest<Venta> = Venta.fetchRequest()
        request.predicate = NSPredicate(format: "fechaVenta >= %@ AND fechaVenta <= %@", desde as NSDate, hasta as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "fechaVenta", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Total ventas
    func totalVentas() -> Int {
        let request: NSFetchRequest<Venta> = Venta.fetchRequest()
        return (try? context.count(for: request)) ?? 0
    }
    
    // MARK: - Monto total vendido
    func montoTotalVendido() -> Double {
        let ventas = obtenerTodas()
        return ventas.reduce(0) { $0 + $1.total }
    }
    
    // MARK: - Eliminar
    func eliminar(_ venta: Venta) {
        if let producto = venta.producto {
            producto.stock += venta.cantidad
        }
        context.delete(venta)
        PersistenceController.shared.save()
    }
}

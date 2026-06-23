import CoreData

class VentaRepository {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.context) {
        self.context = context
    }
    
    // MARK: - Generar código de venta
    private func generarCodigoVenta() -> String {
        let request: NSFetchRequest<Venta> = Venta.fetchRequest()
        request.predicate = NSPredicate(format: "codigoVenta != nil")
        request.sortDescriptors = [NSSortDescriptor(key: "codigoVenta", ascending: false)]
        request.fetchLimit = 1
        let ultimo = (try? context.fetch(request))?.first?.codigoVenta ?? "FV-00000"
        let numero = Int(ultimo.dropFirst(3)) ?? 0
        return String(format: "FV-%05d", numero + 1)
    }

    // MARK: - Crear (multi-producto)
    func crear(cliente: Cliente, productos: [(producto: Producto, cantidad: Int)]) {
        let venta = Venta(context: context)
        venta.idVenta     = UUID()
        venta.codigoVenta = generarCodigoVenta()
        venta.fechaVenta  = Date()
        venta.cliente     = cliente

        var subtotalTotal: Double = 0
        for item in productos {
            let subtotal = Double(item.cantidad) * item.producto.precio
            subtotalTotal += subtotal

            let detalle = DetalleVenta(context: context)
            detalle.idDetalle     = UUID()
            detalle.cantidad      = Int32(item.cantidad)
            detalle.precioUnitario = item.producto.precio
            detalle.subtotal      = subtotal
            detalle.producto      = item.producto
            detalle.venta         = venta

            item.producto.stock -= Int32(item.cantidad)

            if item.producto.stock <= 5 {
                NotificationManager.shared.scheduleLowStockAlert(
                    productName: item.producto.nombre ?? "",
                    stock: Int(item.producto.stock),
                    codigo: item.producto.codigo ?? ""
                )
            }
        }

        venta.subtotal = subtotalTotal
        venta.igv      = subtotalTotal * AppConstants.igvRate
        venta.total    = subtotalTotal + venta.igv

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
        if let detalles = venta.detalles as? Set<DetalleVenta> {
            for detalle in detalles {
                if let producto = detalle.producto {
                    producto.stock += detalle.cantidad
                }
            }
        }
        context.delete(venta)
        PersistenceController.shared.save()
    }
}

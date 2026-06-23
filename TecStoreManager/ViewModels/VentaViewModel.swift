import Foundation
import CoreData

class VentaViewModel: ObservableObject {
    
    @Published var ventas: [Venta]      = []
    @Published var errorMessage: String = ""
    @Published var searchText: String   = ""
    @Published var fechaDesde: Date     = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var fechaHasta: Date     = Date()
    
    private let repository:         VentaRepository
    private let productoRepository: ProductoRepository
    
    init(
        repository:         VentaRepository     = VentaRepository(),
        productoRepository: ProductoRepository  = ProductoRepository()
    ) {
        self.repository         = repository
        self.productoRepository = productoRepository
        cargar()
    }
    
    // MARK: - Cargar
    func cargar() {
        ventas = repository.obtenerTodas()
    }
    
    // MARK: - Crear (multi-producto)
    func crear(cliente: Cliente, productos: [(producto: Producto, cantidad: Int)], metodoPago: String = "") -> Bool {
        guard !productos.isEmpty else {
            errorMessage = "Agrega al menos un producto"
            return false
        }

        for item in productos {
            if let error = Validators.validarVenta(
                cantidad: item.cantidad,
                stockActual: Int(item.producto.stock)
            ) {
                errorMessage = "\(item.producto.nombre ?? ""): \(error)"
                return false
            }
        }

        repository.crear(cliente: cliente, productos: productos, metodoPago: metodoPago)
        cargar()
        errorMessage = ""
        return true
    }
    
    // MARK: - Eliminar
    func eliminar(_ venta: Venta) {
        repository.eliminar(venta)
        cargar()
    }
    
    // MARK: - Buscar por cliente
    func buscarPorCliente() {
        if searchText.isEmpty {
            cargar()
        } else {
            ventas = repository.buscarPorCliente(searchText)
        }
    }
    
    // MARK: - Buscar por fecha
    func buscarPorFecha() {
        ventas = repository.buscarPorFecha(desde: fechaDesde, hasta: fechaHasta)
    }
    
    // MARK: - Calcular preview (multi-producto)
    func calcularPreview(productos: [(producto: Producto, cantidad: Int)]) -> (subtotal: Double, igv: Double, total: Double) {
        let subtotal = productos.reduce(0.0) { $0 + (Double($1.cantidad) * $1.producto.precio) }
        let igv      = subtotal * AppConstants.igvRate
        let total    = subtotal + igv
        return (subtotal, igv, total)
    }
    
    // MARK: - Reportes
    func totalVentas() -> Int {
        return repository.totalVentas()
    }
    
    func montoTotalVendido() -> Double {
        return repository.montoTotalVendido()
    }
}

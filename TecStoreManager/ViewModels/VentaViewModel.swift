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
    
    // MARK: - Crear
    func crear(cantidadStr: String, cliente: Cliente, producto: Producto) -> Bool {
        guard let cantidad = Int(cantidadStr) else {
            errorMessage = "La cantidad debe ser un número válido"
            return false
        }
        
        if let error = Validators.validarVenta(
            cantidad: cantidad,
            stockActual: Int(producto.stock)
        ) {
            errorMessage = error
            return false
        }
        
        repository.crear(
            cantidad: cantidad,
            precio: producto.precio,
            cliente: cliente,
            producto: producto
        )
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
    
    // MARK: - Calcular preview
    func calcularPreview(cantidadStr: String, precio: Double) -> (subtotal: Double, igv: Double, total: Double) {
        let cantidad = Double(cantidadStr) ?? 0
        let subtotal = cantidad * precio
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

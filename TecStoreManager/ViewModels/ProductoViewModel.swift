import Foundation
import CoreData

class ProductoViewModel: ObservableObject {
    
    @Published var productos: [Producto] = []
    @Published var errorMessage: String  = ""
    @Published var searchText: String    = ""
    
    private let repository: ProductoRepository
    
    init(repository: ProductoRepository = ProductoRepository()) {
        self.repository = repository
        cargar()
    }
    
    // MARK: - Cargar
    func cargar() {
        productos = repository.obtenerTodos()
    }
    
    // MARK: - Crear
    func crear(codigo: String, nombre: String, categoria: String, precioStr: String, stockStr: String, imagenPath: String? = nil) -> Bool {
        guard let precio = Double(precioStr),
              let stock  = Int(stockStr) else {
            errorMessage = "Precio y stock deben ser números válidos"
            return false
        }
        
        if let error = Validators.validarProducto(
            nombre: nombre,
            codigo: codigo,
            categoria: categoria,
            precio: precio,
            stock: stock
        ) {
            errorMessage = error
            return false
        }
        
        repository.crear(
            codigo: codigo,
            nombre: nombre,
            categoria: categoria,
            precio: precio,
            stock: stock,
            imagenPath: imagenPath
        )
        cargar()
        errorMessage = ""
        return true
    }
    
    // MARK: - Actualizar
    func actualizar(_ producto: Producto, codigo: String, nombre: String, categoria: String, precioStr: String, stockStr: String, imagenPath: String? = nil) -> Bool {
        guard let precio = Double(precioStr),
              let stock  = Int(stockStr) else {
            errorMessage = "Precio y stock deben ser números válidos"
            return false
        }
        
        if let error = Validators.validarProducto(
            nombre: nombre,
            codigo: codigo,
            categoria: categoria,
            precio: precio,
            stock: stock
        ) {
            errorMessage = error
            return false
        }
        
        repository.actualizar(
            producto,
            codigo: codigo,
            nombre: nombre,
            categoria: categoria,
            precio: precio,
            stock: stock,
            imagenPath: imagenPath
        )
        cargar()
        errorMessage = ""
        return true
    }
    
    // MARK: - Eliminar
    func eliminar(_ producto: Producto) {
        repository.eliminar(producto)
        cargar()
    }
    
    // MARK: - Buscar
    func buscar() {
        if searchText.isEmpty {
            cargar()
        } else {
            productos = repository.buscarPorNombre(searchText)
        }
    }
    
    // MARK: - Filtrar por categoria
    func filtrarPorCategoria(_ categoria: String) {
        if categoria == "Todos" {
            cargar()
        } else {
            productos = repository.filtrarPorCategoria(categoria)
        }
    }
    
    // MARK: - Producto menor stock
    func productoMenorStock() -> Producto? {
        return repository.productoMenorStock()
    }
    
    // MARK: - Categorias unicas
    var categorias: [String] {
        let cats = productos.compactMap { $0.categoria }
        return ["Todos"] + Array(Set(cats)).sorted()
    }
}

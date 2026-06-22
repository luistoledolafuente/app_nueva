import Foundation

enum Validators {
    
    // MARK: - Campos vacíos
    static func isNotEmpty(_ value: String) -> Bool {
        return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Precio
    static func isPrecioValido(_ precio: Double) -> Bool {
        return precio > 0
    }
    
    // MARK: - Stock
    static func isStockValido(_ stock: Int) -> Bool {
        return stock >= 0
    }
    
    // MARK: - Cantidad de venta
    static func isCantidadValida(_ cantidad: Int) -> Bool {
        return cantidad > 0
    }
    
    // MARK: - DNI
    static func isDNIValido(_ dni: String) -> Bool {
        let dni = dni.trimmingCharacters(in: .whitespacesAndNewlines)
        return dni.count == 8 && dni.allSatisfy({ $0.isNumber })
    }
    
    // MARK: - Correo
    static func isCorreoValido(_ correo: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: correo)
    }
    
    // MARK: - Stock suficiente
    static func hayStockSuficiente(stockActual: Int, cantidad: Int) -> Bool {
        return stockActual >= cantidad
    }
    
    // MARK: - Validar producto
    static func validarProducto(nombre: String, codigo: String, categoria: String, precio: Double, stock: Int) -> String? {
        if !isNotEmpty(nombre)     { return "El nombre es obligatorio" }
        if !isNotEmpty(codigo)     { return "El código es obligatorio" }
        if !isNotEmpty(categoria)  { return "La categoría es obligatoria" }
        if !isPrecioValido(precio) { return "El precio debe ser mayor a 0" }
        if !isStockValido(stock)   { return "El stock no puede ser negativo" }
        return nil
    }
    
    // MARK: - Validar cliente
    static func validarCliente(nombres: String, apellidos: String, dni: String, correo: String, telefono: String) -> String? {
        if !isNotEmpty(nombres)    { return "El nombre es obligatorio" }
        if !isNotEmpty(apellidos)  { return "Los apellidos son obligatorios" }
        if !isDNIValido(dni)       { return "El DNI debe tener 8 dígitos" }
        if !isCorreoValido(correo) { return "El correo no tiene formato válido" }
        if !isNotEmpty(telefono)   { return "El teléfono es obligatorio" }
        return nil
    }
    
    // MARK: - Validar venta
    static func validarVenta(cantidad: Int, stockActual: Int) -> String? {
        if !isCantidadValida(cantidad) { return "La cantidad debe ser mayor a 0" }
        if !hayStockSuficiente(stockActual: stockActual, cantidad: cantidad) {
            return "No hay stock suficiente para esta venta"
        }
        return nil
    }
}

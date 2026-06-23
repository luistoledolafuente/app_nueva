import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

enum FirestoreCollection {
    static let clientes  = "clientes"
    static let productos = "productos"
    static let ventas    = "ventas"
    static let detalles  = "detallesVenta"
    static let ubicaciones = "ubicaciones"
}

struct FSCliente: Codable {
    var id: String
    var nombres: String
    var apellidos: String
    var dni: String
    var correo: String
    var telefono: String
    var direccion: String
    var estado: Bool
    var updatedAt: TimestampValue

    init(from cd: Cliente) {
        id = cd.idCliente?.uuidString ?? UUID().uuidString
        nombres = cd.nombres ?? ""
        apellidos = cd.apellidos ?? ""
        dni = cd.dni ?? ""
        correo = cd.correo ?? ""
        telefono = cd.telefono ?? ""
        direccion = cd.direccion ?? ""
        estado = cd.estado
        updatedAt = TimestampValue()
    }
}

struct FSProducto: Codable {
    var id: String
    var nombre: String
    var codigo: String
    var categoria: String
    var precio: Double
    var stock: Int
    var estado: Bool
    var imagenPath: String
    var updatedAt: TimestampValue

    init(from cd: Producto) {
        id = cd.idProducto?.uuidString ?? UUID().uuidString
        nombre = cd.nombre ?? ""
        codigo = cd.codigo ?? ""
        categoria = cd.categoria ?? ""
        precio = cd.precio
        stock = Int(cd.stock)
        estado = cd.estado
        imagenPath = cd.imagenPath ?? ""
        updatedAt = TimestampValue()
    }
}

struct FSVenta: Codable {
    var id: String
    var codigoVenta: String
    var fechaVenta: TimestampValue
    var clienteId: String
    var subtotal: Double
    var igv: Double
    var total: Double
    var metodoPago: String
    var updatedAt: TimestampValue

    init(from cd: Venta) {
        id = cd.idVenta?.uuidString ?? UUID().uuidString
        codigoVenta = cd.codigoVenta ?? ""
        fechaVenta = TimestampValue(date: cd.fechaVenta ?? Date())
        clienteId = cd.cliente?.idCliente?.uuidString ?? ""
        subtotal = cd.subtotal
        igv = cd.igv
        total = cd.total
        metodoPago = cd.metodoPago ?? ""
        updatedAt = TimestampValue()
    }
}

struct FSDetalleVenta: Codable {
    var id: String
    var ventaId: String
    var productoId: String
    var cantidad: Int
    var precioUnitario: Double
    var subtotal: Double
    var descuento: Double

    init(from cd: DetalleVenta) {
        id = cd.idDetalle?.uuidString ?? UUID().uuidString
        ventaId = cd.venta?.idVenta?.uuidString ?? ""
        productoId = cd.producto?.idProducto?.uuidString ?? ""
        cantidad = Int(cd.cantidad)
        precioUnitario = cd.precioUnitario
        subtotal = cd.subtotal
        descuento = cd.descuento
    }
}

struct FSUbicacion: Codable {
    var id: String
    var latitud: Double
    var longitud: Double
    var direccionReferencia: String
    var fechaRegistro: TimestampValue
    var updatedAt: TimestampValue

    init(from cd: Ubicacion) {
        id = cd.idUbicacion?.uuidString ?? UUID().uuidString
        latitud = cd.latitud
        longitud = cd.longitud
        direccionReferencia = cd.direccionReferencia ?? ""
        fechaRegistro = TimestampValue(date: cd.fechaRegistro ?? Date())
        updatedAt = TimestampValue()
    }
}

struct TimestampValue: Codable {
    var seconds: Int64
    var nanos: Int32

    init() {
        let t = Int64(Date().timeIntervalSince1970)
        seconds = t
        nanos = 0
    }

    init(date: Date) {
        let t = Int64(date.timeIntervalSince1970)
        seconds = t
        nanos = 0
    }

    var dateValue: Date {
        Date(timeIntervalSince1970: TimeInterval(seconds))
    }
}

enum SyncStatus {
    case synced, pending, offline, error(String)
}

import Foundation
import CoreData

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

class SyncService {
    static let shared = SyncService()

    private let context: NSManagedObjectContext

    @Published var lastSyncDate: Date?
    @Published var syncStatus: SyncStatus = .synced

    private init() {
        context = PersistenceController.shared.context
    }

    func pushCliente(_ cliente: Cliente) {
        #if canImport(FirebaseFirestore)
        let fs = FSCliente(from: cliente)
        let data = encode(fs)
        Firestore.firestore()
            .collection(FirestoreCollection.clientes)
            .document(fs.id)
            .setData(data, merge: true)
        #endif
    }

    func deleteCliente(_ id: String) {
        #if canImport(FirebaseFirestore)
        Firestore.firestore()
            .collection(FirestoreCollection.clientes)
            .document(id)
            .delete()
        #endif
    }

    func pushProducto(_ producto: Producto) {
        #if canImport(FirebaseFirestore)
        let fs = FSProducto(from: producto)
        let data = encode(fs)
        Firestore.firestore()
            .collection(FirestoreCollection.productos)
            .document(fs.id)
            .setData(data, merge: true)
        #endif
    }

    func deleteProducto(_ id: String) {
        #if canImport(FirebaseFirestore)
        Firestore.firestore()
            .collection(FirestoreCollection.productos)
            .document(id)
            .delete()
        #endif
    }

    func pushVenta(_ venta: Venta) {
        #if canImport(FirebaseFirestore)
        let fs = FSVenta(from: venta)
        let data = encode(fs)
        Firestore.firestore()
            .collection(FirestoreCollection.ventas)
            .document(fs.id)
            .setData(data, merge: true)

        if let detalles = venta.detalles as? Set<DetalleVenta> {
            let batch = Firestore.firestore().batch()
            for detalle in detalles {
                let fsd = FSDetalleVenta(from: detalle)
                let ref = Firestore.firestore()
                    .collection(FirestoreCollection.ventas)
                    .document(fs.id)
                    .collection(FirestoreCollection.detalles)
                    .document(fsd.id)
                batch.setData(encode(fsd), forDocument: ref, merge: true)
            }
            batch.commit()
        }
        #endif
    }

    func deleteVenta(_ id: String) {
        #if canImport(FirebaseFirestore)
        let ref = Firestore.firestore()
            .collection(FirestoreCollection.ventas)
            .document(id)
        ref.delete()
        ref.collection(FirestoreCollection.detalles).getDocuments { snap, _ in
            snap?.documents.forEach { $0.reference.delete() }
        }
        #endif
    }

    func pushUbicacion(_ ubicacion: Ubicacion) {
        #if canImport(FirebaseFirestore)
        let fs = FSUbicacion(from: ubicacion)
        Firestore.firestore()
            .collection(FirestoreCollection.ubicaciones)
            .document(fs.id)
            .setData(encode(fs), merge: true)
        #endif
    }

    func deleteUbicacion(_ id: String) {
        #if canImport(FirebaseFirestore)
        Firestore.firestore()
            .collection(FirestoreCollection.ubicaciones)
            .document(id)
            .delete()
        #endif
    }

    func pullAll() async {
        #if canImport(FirebaseFirestore)
        syncStatus = .pending
        await pullClientes()
        await pullProductos()
        await pullVentas()
        await pullUbicaciones()
        lastSyncDate = Date()
        syncStatus = .synced
        #endif
    }

    private func pullClientes() async {
        #if canImport(FirebaseFirestore)
        do {
            let snap = try await Firestore.firestore()
                .collection(FirestoreCollection.clientes)
                .getDocuments()
            for doc in snap.documents {
                let fs = try doc.data(as: FSCliente.self, decoder: Firestore.Decoder())
                saveClienteFromFS(fs)
            }
        } catch {
            syncStatus = .error("Error pulling clientes: \(error.localizedDescription)")
        }
        #endif
    }

    private func pullProductos() async {
        #if canImport(FirebaseFirestore)
        do {
            let snap = try await Firestore.firestore()
                .collection(FirestoreCollection.productos)
                .getDocuments()
            for doc in snap.documents {
                let fs = try doc.data(as: FSProducto.self, decoder: Firestore.Decoder())
                saveProductoFromFS(fs)
            }
        } catch {
            syncStatus = .error("Error pulling productos: \(error.localizedDescription)")
        }
        #endif
    }

    private func pullVentas() async {
        #if canImport(FirebaseFirestore)
        do {
            let batch = Firestore.firestore().batch()
            let snap = try await Firestore.firestore()
                .collection(FirestoreCollection.ventas)
                .getDocuments()
            for doc in snap.documents {
                let fs = try doc.data(as: FSVenta.self, decoder: Firestore.Decoder())
                let venta = saveVentaFromFS(fs)
                let detallesSnap = try await doc.reference
                    .collection(FirestoreCollection.detalles)
                    .getDocuments()
                for dDoc in detallesSnap.documents {
                    let fsd = try dDoc.data(as: FSDetalleVenta.self, decoder: Firestore.Decoder())
                    saveDetalleFromFS(fsd, venta: venta)
                }
            }
            try context.save()
        } catch {
            syncStatus = .error("Error pulling ventas: \(error.localizedDescription)")
        }
        #endif
    }

    private func pullUbicaciones() async {
        #if canImport(FirebaseFirestore)
        do {
            let snap = try await Firestore.firestore()
                .collection(FirestoreCollection.ubicaciones)
                .getDocuments()
            for doc in snap.documents {
                let fs = try doc.data(as: FSUbicacion.self, decoder: Firestore.Decoder())
                saveUbicacionFromFS(fs)
            }
        } catch {
            syncStatus = .error("Error pulling ubicaciones: \(error.localizedDescription)")
        }
        #endif
    }

    // MARK: - Helpers

    private func saveClienteFromFS(_ fs: FSCliente) {
        let req = Cliente.fetchRequest()
        req.predicate = NSPredicate(format: "idCliente == %@", fs.id)
        let cd: Cliente
        if let existing = (try? context.fetch(req))?.first {
            cd = existing
        } else {
            cd = Cliente(context: context)
            cd.idCliente = UUID(uuidString: fs.id) ?? UUID()
        }
        cd.nombres = fs.nombres
        cd.apellidos = fs.apellidos
        cd.dni = fs.dni
        cd.correo = fs.correo
        cd.telefono = fs.telefono
        cd.direccion = fs.direccion
        cd.estado = fs.estado
    }

    private func saveProductoFromFS(_ fs: FSProducto) {
        let req = Producto.fetchRequest()
        req.predicate = NSPredicate(format: "idProducto == %@", fs.id)
        let cd: Producto
        if let existing = (try? context.fetch(req))?.first {
            cd = existing
        } else {
            cd = Producto(context: context)
            cd.idProducto = UUID(uuidString: fs.id) ?? UUID()
        }
        cd.nombre = fs.nombre
        cd.codigo = fs.codigo
        cd.categoria = fs.categoria
        cd.precio = fs.precio
        cd.stock = Int32(fs.stock)
        cd.estado = fs.estado
        cd.imagenPath = fs.imagenPath
    }

    @discardableResult
    private func saveVentaFromFS(_ fs: FSVenta) -> Venta {
        let req = Venta.fetchRequest()
        req.predicate = NSPredicate(format: "idVenta == %@", fs.id)
        let cd: Venta
        if let existing = (try? context.fetch(req))?.first {
            cd = existing
        } else {
            cd = Venta(context: context)
            cd.idVenta = UUID(uuidString: fs.id) ?? UUID()
        }
        cd.codigoVenta = fs.codigoVenta
        cd.fechaVenta = fs.fechaVenta.dateValue
        cd.subtotal = fs.subtotal
        cd.igv = fs.igv
        cd.total = fs.total
        cd.metodoPago = fs.metodoPago

        let clienteReq = Cliente.fetchRequest()
        clienteReq.predicate = NSPredicate(format: "idCliente == %@", fs.clienteId)
        cd.cliente = (try? context.fetch(clienteReq))?.first
        return cd
    }

    private func saveDetalleFromFS(_ fs: FSDetalleVenta, venta: Venta) {
        let req = DetalleVenta.fetchRequest()
        req.predicate = NSPredicate(format: "idDetalle == %@", fs.id)
        let cd: DetalleVenta
        if let existing = (try? context.fetch(req))?.first {
            cd = existing
        } else {
            cd = DetalleVenta(context: context)
            cd.idDetalle = UUID(uuidString: fs.id) ?? UUID()
        }
        cd.cantidad = Int32(fs.cantidad)
        cd.precioUnitario = fs.precioUnitario
        cd.subtotal = fs.subtotal
        cd.descuento = fs.descuento
        cd.venta = venta

        let prodReq = Producto.fetchRequest()
        prodReq.predicate = NSPredicate(format: "idProducto == %@", fs.productoId)
        cd.producto = (try? context.fetch(prodReq))?.first
    }

    private func saveUbicacionFromFS(_ fs: FSUbicacion) {
        let req = Ubicacion.fetchRequest()
        req.predicate = NSPredicate(format: "idUbicacion == %@", fs.id)
        let cd: Ubicacion
        if let existing = (try? context.fetch(req))?.first {
            cd = existing
        } else {
            cd = Ubicacion(context: context)
            cd.idUbicacion = UUID(uuidString: fs.id) ?? UUID()
        }
        cd.latitud = fs.latitud
        cd.longitud = fs.longitud
        cd.direccionReferencia = fs.direccionReferencia
        cd.fechaRegistro = fs.fechaRegistro.dateValue
    }

    private func encode<T: Encodable>(_ value: T) -> [String: Any] {
        #if canImport(FirebaseFirestore)
        return (try? Firestore.Encoder().encode(value)) ?? [:]
        #else
        return [:]
        #endif
    }
}

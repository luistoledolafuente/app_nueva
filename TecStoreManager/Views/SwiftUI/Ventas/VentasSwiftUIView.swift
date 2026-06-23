import SwiftUI

struct VentasSwiftUIView: View {
    @StateObject private var vm    = VentaViewModel()
    @State private var search      = ""
    @State private var showForm    = false
    @State private var toDelete: Venta? = nil
    @State private var showDeleteAlert  = false

    private var displayed: [Venta] {
        if search.isEmpty { return vm.ventas }
        return vm.ventas.filter {
            let cliente = "\(($0.cliente?.nombres ?? "")) \(($0.cliente?.apellidos ?? ""))"
            return cliente.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBlock
            salesList
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.npBg.ignoresSafeArea())
        .navigationTitle("Ventas")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showForm = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.npEmerald)
                }
            }
        }
        .sheet(isPresented: $showForm, onDismiss: { vm.cargar() }) {
            VentaFormSwiftUIView(vm: vm)
        }
        .alert("Eliminar venta", isPresented: $showDeleteAlert) {
            Button("Eliminar", role: .destructive) { if let v = toDelete { vm.eliminar(v) } }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("¿Seguro que deseas eliminar esta venta? El stock será restaurado.")
        }
        .onAppear { vm.cargar() }
    }

    private var headerBlock: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "cart.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.npEmerald)
                Text("\(vm.totalVentas()) ventas")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.npPrimary)
                Spacer()
                Text("\(displayed.count) resultados")
                    .font(.system(size: 12))
                    .foregroundColor(.npSlate)
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.npSlate)
                    .font(.system(size: 15, weight: .medium))
                TextField("", text: $search, prompt: Text("Buscar por cliente...").foregroundColor(.npSlate))
                    .font(.system(size: 15))
                    .foregroundColor(.npPrimary)
                if !search.isEmpty {
                    Button { search = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.npSlate)
                    }
                }
            }
            .padding(10)
            .overlay(
                Rectangle()
                    .fill(!search.isEmpty ? Color.npEmerald : Color.npBorder)
                    .frame(height: 1),
                alignment: .bottom
            )
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var salesList: some View {
        if displayed.isEmpty {
            NPEmptyState(
                icon: "cart",
                title: "Sin ventas",
                subtitle: search.isEmpty ? "Registra tu primera venta" : "No se encontraron resultados"
            )
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(displayed, id: \.idVenta) { venta in
                        VentaCard(venta: venta)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    toDelete = venta; showDeleteAlert = true
                                } label: { Label("Eliminar", systemImage: "trash") }
                            }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
        }
    }
}

private struct VentaCard: View {
    let venta: Venta

    private var clienteName: String {
        "\(venta.cliente?.nombres ?? "") \(venta.cliente?.apellidos ?? "")"
    }

    private var productosResumen: String {
        let detalles = venta.detalles as? Set<DetalleVenta> ?? []
        let nombres = detalles.compactMap { $0.producto?.nombre }.filter { !$0.isEmpty }
        if nombres.isEmpty { return "-" }
        if nombres.count == 1 { return nombres[0] }
        return "\(nombres[0]) + \(nombres.count - 1) más"
    }

    private var totalProductos: Int {
        (venta.detalles as? Set<DetalleVenta>)?.count ?? 0
    }

    var body: some View {
        NPTopCard(color: .npEmerald) {
            HStack(spacing: 14) {
                NPAvatar(name: clienteName, gradient: .ventas)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(venta.codigoVenta ?? "---")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.npEmerald)
                        NPBadge(text: "\(totalProductos) prod.", color: .npSecondary)
                    }
                    Text(clienteName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.npPrimary)
                    HStack(spacing: 6) {
                        Image(systemName: "shippingbox").font(.caption2).foregroundColor(.npSlate)
                        Text(productosResumen)
                            .font(.system(size: 13)).foregroundColor(.npSlate).lineLimit(1)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "calendar").font(.caption2).foregroundColor(.npSlate)
                        Text(formatDate(venta.fechaVenta))
                            .font(.system(size: 12)).foregroundColor(.npSlate)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text(formatCurrency(venta.total))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.npEmerald)
                }
            }
            .padding(14)
        }
    }
}

// MARK: - Formulario SwiftUI multi-producto
struct VentaFormSwiftUIView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm:     VentaViewModel
    @StateObject private var clienteVM  = ClienteViewModel()
    @StateObject private var productoVM = ProductoViewModel()

    @State private var clienteIdx    = 0
    @State private var itemsCarrito: [(producto: Producto, cantidad: Int)] = []
    @State private var error        = ""

    private var activeClientes:  [Cliente]  { clienteVM.clientes.filter  { $0.estado } }
    private var activeProductos: [Producto] { productoVM.productos.filter { $0.estado && $0.stock > 0 } }

    private var preview: (subtotal: Double, igv: Double, total: Double) {
        vm.calcularPreview(productos: itemsCarrito)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientGlowBackground(firstColor: Color(hex: "#059669"), secondColor: Color(hex: "#6366F1"))
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            ZStack {
                                PolygonShape(sides: 6)
                                    .fill(NPGradient.ventas.gradient)
                                    .frame(width: 80, height: 80)
                                Image(systemName: "cart.badge.plus")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .shadow(color: Color(hex: "#059669").opacity(0.3), radius: 12)
                            .padding(.top, 24)
                        }

                        VStack(spacing: 20) {
                            Text("Nueva Venta")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            pickerSection(label: "Cliente", icon: "person.fill") {
                                if activeClientes.isEmpty {
                                    Text("No hay clientes activos").foregroundColor(.npDanger).font(.caption)
                                } else {
                                    Picker("Cliente", selection: $clienteIdx) {
                                        ForEach(activeClientes.indices, id: \.self) { i in
                                            Text("\(activeClientes[i].nombres ?? "") \(activeClientes[i].apellidos ?? "")").tag(i)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .pickerBackground()
                                }
                            }

                            // Carrito de productos
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Productos", systemImage: "shippingbox.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color.white.opacity(0.6))

                                if itemsCarrito.isEmpty {
                                    Text("No hay productos agregados")
                                        .font(.caption)
                                        .foregroundColor(Color.white.opacity(0.4))
                                        .padding(12)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white.opacity(0.06))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                } else {
                                    ForEach(itemsCarrito.indices, id: \.self) { i in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(itemsCarrito[i].producto.nombre ?? "")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.white)
                                                Text("x\(itemsCarrito[i].cantidad) · S/ \(String(format: "%.2f", itemsCarrito[i].producto.precio)) c/u")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Color.white.opacity(0.5))
                                            }
                                            Spacer()
                                            Text("S/ \(String(format: "%.2f", Double(itemsCarrito[i].cantidad) * itemsCarrito[i].producto.precio))")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.npEmerald)
                                            Button {
                                                itemsCarrito.remove(at: i)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.npDanger)
                                                    .font(.system(size: 18))
                                            }
                                            .padding(.leading, 8)
                                        }
                                        .padding(12)
                                        .background(Color.white.opacity(0.06))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }

                                Button {
                                    seleccionarProducto()
                                } label: {
                                    Label("Agregar Producto", systemImage: "plus.circle")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.npEmerald)
                                        .padding(10)
                                        .frame(maxWidth: .infinity)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.npEmerald.opacity(0.5), lineWidth: 1)
                                        )
                                }
                            }

                            if !itemsCarrito.isEmpty {
                                pricePreview
                            }

                            NPErrorBanner(message: error)

                            Button {
                                guard !activeClientes.isEmpty else {
                                    error = "Selecciona un cliente"; return
                                }
                                guard !itemsCarrito.isEmpty else {
                                    error = "Agrega al menos un producto"; return
                                }
                                if vm.crear(cliente: activeClientes[clienteIdx], productos: itemsCarrito) {
                                    dismiss()
                                } else { error = vm.errorMessage }
                            } label: {
                                Text("Registrar venta (\(itemsCarrito.count) producto\(itemsCarrito.count != 1 ? "s" : ""))")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#059669"), Color(hex: "#047857")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color(hex: "#059669").opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 24, x: 0, y: 12)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func seleccionarProducto() {
        guard !activeProductos.isEmpty else {
            error = "No hay productos disponibles"
            return
        }
        // Usamos UIAlertController via UIKit porque SwiftUI picker es muy limitado
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else { return }

        let alert = UIAlertController(title: "Agregar Producto", message: nil, preferredStyle: .actionSheet)
        for producto in activeProductos {
            alert.addAction(UIAlertAction(title: "\(producto.nombre ?? "") - S/ \(String(format: "%.2f", producto.precio)) (Stock: \(producto.stock))", style: .default) { _ in
                pedirCantidad(producto: producto)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        root.present(alert, animated: true)
    }

    private func pedirCantidad(producto: Producto) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else { return }

        let alert = UIAlertController(title: "Cantidad", message: "Producto: \(producto.nombre ?? "")\nStock: \(producto.stock)", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Cantidad"
            tf.keyboardType = .numberPad
        }
        alert.addAction(UIAlertAction(title: "Agregar", style: .default) { _ in
            let cantidadStr = alert.textFields?.first?.text ?? ""
            guard let cantidad = Int(cantidadStr), cantidad > 0, cantidad <= producto.stock else {
                error = "Cantidad inválida o excede el stock"
                return
            }
            if let idx = itemsCarrito.firstIndex(where: { $0.producto.idProducto == producto.idProducto }) {
                let nuevaCant = itemsCarrito[idx].cantidad + cantidad
                if nuevaCant > producto.stock {
                    error = "Stock insuficiente para \(producto.nombre ?? "")"
                    return
                }
                itemsCarrito[idx].cantidad = nuevaCant
            } else {
                itemsCarrito.append((producto, cantidad))
            }
            error = ""
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        root.present(alert, animated: true)
    }

    @ViewBuilder
    private func pickerSection<Content: View>(label: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.6))
            content()
        }
    }

    private var pricePreview: some View {
        VStack(spacing: 0) {
            Text("Resumen de venta")
                .font(.system(size: 13, weight: .bold)).foregroundColor(Color.white.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 10)
            HStack {
                Text("Subtotal").foregroundColor(Color.white.opacity(0.5))
                Spacer()
                Text(formatCurrency(preview.subtotal)).foregroundColor(.white).bold()
            }
            Divider()
                .background(Color.white.opacity(0.12))
                .padding(.vertical, 8)
            HStack {
                Text("IGV (18%)").foregroundColor(Color.white.opacity(0.5))
                Spacer()
                Text(formatCurrency(preview.igv)).foregroundColor(.npAmber).bold()
            }
            Divider()
                .background(Color.white.opacity(0.12))
                .padding(.vertical, 8)
            HStack {
                Text("TOTAL").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                Spacer()
                Text(formatCurrency(preview.total))
                    .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.npEmerald)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.npEmerald.opacity(0.3), lineWidth: 1))
    }
}

private extension View {
    func pickerBackground() -> some View {
        self
            .tint(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}

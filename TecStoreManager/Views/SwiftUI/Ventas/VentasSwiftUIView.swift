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

// MARK: - Formulario SwiftUI multi-producto (Market UX)
struct VentaFormSwiftUIView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm:     VentaViewModel
    @StateObject private var clienteVM  = ClienteViewModel()
    @StateObject private var productoVM = ProductoViewModel()
    @State private var searchTexto = ""

    @State private var clienteIdx    = 0
    @State private var itemsCarrito: [(producto: Producto, cantidad: Int)] = []
    @State private var error      = ""

    private var activeClientes:  [Cliente]  { clienteVM.clientes.filter  { $0.estado } }
    private var activeProductos: [Producto] {
        let base = productoVM.productos.filter { $0.estado }
        if searchTexto.isEmpty { return base }
        return base.filter { ($0.nombre ?? "").localizedCaseInsensitiveContains(searchTexto) }
    }

    private var preview: (subtotal: Double, igv: Double, total: Double) {
        vm.calcularPreview(productos: itemsCarrito)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.npBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button("Cancelar") { dismiss() }
                            .foregroundColor(.npDanger)
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Text("Nueva Venta")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.npPrimary)
                        Spacer()
                        Button("Hecho") { registrar() }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(itemsCarrito.isEmpty ? .npSlate : .npSecondary)
                            .disabled(itemsCarrito.isEmpty)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color.npCard)

                    ScrollView {
                        VStack(spacing: 0) {
                            // Cliente
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CLIENTE".uppercased())
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.npSlate)
                                    .padding(.horizontal, 18)
                                    .padding(.top, 14)

                                if activeClientes.isEmpty {
                                    Text("No hay clientes activos")
                                        .font(.system(size: 14))
                                        .foregroundColor(.npDanger)
                                        .padding(.horizontal, 18)
                                } else {
                                    Menu {
                                        ForEach(activeClientes.indices, id: \.self) { i in
                                            Button("\(activeClientes[i].nombres ?? "") \(activeClientes[i].apellidos ?? "")") {
                                                clienteIdx = i
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "person.fill")
                                                .foregroundColor(.npIndigo)
                                                .font(.system(size: 14))
                                            Text(activeClientes.isEmpty ? "Seleccionar" : "\(activeClientes[clienteIdx].nombres ?? "") \(activeClientes[clienteIdx].apellidos ?? "")")
                                                .font(.system(size: 15))
                                                .foregroundColor(.npPrimary)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundColor(.npSlate)
                                        }
                                        .padding(14)
                                        .background(Color.npCard)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.04), radius: 4)
                                        .padding(.horizontal, 14)
                                    }
                                }
                            }
                            .padding(.bottom, 10)

                            // Productos
                            VStack(alignment: .leading, spacing: 0) {
                                Text("PRODUCTOS".uppercased())
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.npSlate)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)

                                // Search
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.npSlate)
                                        .font(.system(size: 14))
                                    TextField("Buscar producto...", text: $searchTexto)
                                        .font(.system(size: 14))
                                        .foregroundColor(.npPrimary)
                                    if !searchTexto.isEmpty {
                                        Button { searchTexto = "" } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.npSlate)
                                        }
                                    }
                                }
                                .padding(10)
                                .background(Color.npCard)
                                .cornerRadius(10)
                                .padding(.horizontal, 14)
                                .padding(.bottom, 8)

                                if activeProductos.isEmpty {
                                    VStack(spacing: 6) {
                                        Image(systemName: "shippingbox")
                                            .font(.system(size: 28))
                                            .foregroundColor(.npSlate.opacity(0.4))
                                        Text(searchTexto.isEmpty ? "No hay productos disponibles" : "Sin resultados para \"\(searchTexto)\"")
                                            .font(.system(size: 13))
                                            .foregroundColor(.npSlate)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 30)
                                } else {
                                    LazyVStack(spacing: 6) {
                                        ForEach(activeProductos.indices, id: \.self) { i in
                                            productRow(activeProductos[i])
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                }
                            }

                            // Carrito
                            VStack(alignment: .leading, spacing: 0) {
                                let totalItems = itemsCarrito.reduce(0) { $0 + $1.cantidad }
                                HStack {
                                    Text("CARRITO\(totalItems > 0 ? " (\(totalItems) item\(totalItems != 1 ? "s" : ""))" : "")".uppercased())
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(totalItems > 0 ? .npSecondary : .npSlate)
                                    Spacer()
                                    if totalItems > 0 {
                                        Text(formatCurrency(itemsCarrito.reduce(0.0) { $0 + Double($1.cantidad) * $1.producto.precio }))
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.npSecondary)
                                    }
                                }
                                .padding(.horizontal, 18)
                                .padding(.top, 14)
                                .padding(.bottom, 6)

                                if itemsCarrito.isEmpty {
                                    HStack {
                                        Spacer()
                                        Text("Toca \"AGREGAR\" en los productos de arriba")
                                            .font(.system(size: 13))
                                            .foregroundColor(.npSlate)
                                            .padding(.vertical, 20)
                                        Spacer()
                                    }
                                } else {
                                    LazyVStack(spacing: 6) {
                                        ForEach(itemsCarrito.indices, id: \.self) { i in
                                            cartItemRow(i)
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.bottom, 6)
                                }
                            }
                            .background(Color.npCard.opacity(0.4))

                            // Totales & Botón
                            if !itemsCarrito.isEmpty {
                                VStack(spacing: 0) {
                                    VStack(spacing: 8) {
                                        totalRow("Subtotal", formatCurrency(preview.subtotal), .npPrimary)
                                        Divider().padding(.horizontal, 4)
                                        totalRow("IGV (18%)", formatCurrency(preview.igv), .npWarning)
                                        Divider().padding(.horizontal, 4)
                                        totalRow("TOTAL", formatCurrency(preview.total), .npSecondary)
                                    }
                                    .padding(16)
                                    .background(Color.npCard)
                                    .cornerRadius(14)
                                    .shadow(color: Color.black.opacity(0.04), radius: 4)

                            Button(action: registrar) {
                                let totalItems = itemsCarrito.reduce(0) { $0 + $1.cantidad }
                                Text("Registrar Venta (\(totalItems) item\(totalItems != 1 ? "s" : ""))")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.npRose)
                                    .cornerRadius(14)
                            }
                            .padding(.top, 14)
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 14)
                            }

                            if !error.isEmpty {
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundColor(.npDanger)
                                    .padding(.horizontal, 18)
                                    .padding(.bottom, 10)
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Product Row
    private func productRow(_ producto: Producto) -> some View {
        let enCarrito = itemsCarrito.first { $0.producto.idProducto == producto.idProducto }
        let cantidad = enCarrito?.cantidad ?? 0
        let sinStock = producto.stock == 0

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(producto.nombre ?? "")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.npPrimary)
                Text("S/ \(String(format: "%.2f", producto.precio))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.npIndigo)
                Text("Stock: \(producto.stock)")
                    .font(.system(size: 11))
                    .foregroundColor(producto.stock <= 5 ? .npDanger : .npSlate)
            }

            Spacer()

            if sinStock {
                Text("AGOTADO")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.npSlate)
                    .cornerRadius(12)
            } else if cantidad > 0 {
                VStack(spacing: 2) {
                    Text("\(cantidad)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        .background(Color.npRose)
                        .clipShape(Circle())
                    Button("+1") {
                        agregarProducto(producto)
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.npSecondary)
                    .cornerRadius(14)
                }
            } else {
                Button("AGREGAR") {
                    agregarProducto(producto)
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.npRose)
                .cornerRadius(16)
            }
        }
        .padding(12)
        .background(Color.npCard)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 2)
    }

    // MARK: - Cart Item Row
    private func cartItemRow(_ index: Int) -> some View {
        let item = itemsCarrito[index]
        return HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.producto.nombre ?? "")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.npPrimary)
                Text("S/ \(String(format: "%.2f", item.producto.precio)) c/u")
                    .font(.system(size: 11))
                    .foregroundColor(.npSlate)
            }

            Spacer()

            // Stepper
            HStack(spacing: 0) {
                Button {
                    if item.cantidad > 1 {
                        itemsCarrito[index].cantidad -= 1
                    } else {
                        itemsCarrito.remove(at: index)
                    }
                } label: {
                    Text("−")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.npDanger)
                        .frame(width: 32, height: 30)
                }
                Text("\(item.cantidad)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.npPrimary)
                    .frame(minWidth: 28)
                Button {
                    if item.cantidad < item.producto.stock {
                        itemsCarrito[index].cantidad += 1
                    }
                } label: {
                    Text("+")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.npSecondary)
                        .frame(width: 32, height: 30)
                }
            }
            .background(Color.npMuted.opacity(0.15))
            .cornerRadius(14)

            Text("S/ \(String(format: "%.2f", Double(item.cantidad) * item.producto.precio))")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.npIndigo)
                .frame(width: 72, alignment: .trailing)

            Button {
                itemsCarrito.remove(at: index)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.npDanger.opacity(0.6))
            }
            .padding(.leading, 2)
        }
        .padding(12)
        .background(Color.npCard)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 2)
    }

    // MARK: - Helpers
    private func agregarProducto(_ producto: Producto) {
        guard producto.stock > 0 else { return }
        if let idx = itemsCarrito.firstIndex(where: { $0.producto.idProducto == producto.idProducto }) {
            guard itemsCarrito[idx].cantidad < producto.stock else {
                error = "Stock máximo alcanzado para \(producto.nombre ?? "")"
                return
            }
            itemsCarrito[idx].cantidad += 1
        } else {
            itemsCarrito.append((producto, 1))
        }
        error = ""
    }

    private func registrar() {
        guard !activeClientes.isEmpty else { error = "Selecciona un cliente"; return }
        guard !itemsCarrito.isEmpty else { error = "Agrega al menos un producto"; return }
        if vm.crear(cliente: activeClientes[clienteIdx], productos: itemsCarrito) {
            dismiss()
        } else { error = vm.errorMessage }
    }

    private func totalRow(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.npSlate)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(color)
        }
    }
}

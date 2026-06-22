import SwiftUI

struct BusquedasSwiftUIView: View {
    @StateObject private var productoVM = ProductoViewModel()
    @StateObject private var clienteVM  = ClienteViewModel()
    @StateObject private var ventaVM    = VentaViewModel()

    @State private var tab    = 0
    @State private var search = ""

    private var tabTitles = ["Productos", "Clientes", "Ventas"]
    private var tabIcons  = ["shippingbox.fill", "person.2.fill", "chart.bar.fill"]
    private var tabGrads: [ModuleGradient] = [.productos, .clientes, .ventas]

    var body: some View {
        ZStack {
            Color.tsBg.ignoresSafeArea()
            VStack(spacing: 0) {
                tabSelector
                searchField
                resultsList
            }
        }
        .navigationTitle("Búsquedas")
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: search) { _ in performSearch() }
        .onChange(of: tab)    { _ in search = ""; performSearch() }
        .onAppear { performSearch() }
    }

    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 10) {
            ForEach(tabTitles.indices, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        tab = i
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tabIcons[i])
                            .font(.system(size: 12, weight: .semibold))
                        Text(tabTitles[i])
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(tab == i ? .white : tabGrads[i].start)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        tab == i
                            ? AnyView(tabGrads[i].gradient)
                            : AnyView(tabGrads[i].start.opacity(0.1))
                    )
                    .clipShape(Capsule())
                }
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    // MARK: - Search Field
    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(tabGrads[tab].start)
            TextField(placeholder, text: $search)
                .font(.system(size: 15))
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.tsSlate)
                }
            }
        }
        .padding(13)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }

    private var placeholder: String {
        switch tab {
        case 0:  return "Buscar producto..."
        case 1:  return "Buscar por nombre o DNI..."
        default: return "Buscar por cliente..."
        }
    }

    // MARK: - Results
    @ViewBuilder
    private var resultsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                switch tab {
                case 0:
                    if productoVM.productos.isEmpty {
                        TSEmptyState(icon: "shippingbox", title: "Sin resultados", subtitle: "Intenta con otro término")
                    } else {
                        ForEach(productoVM.productos, id: \.idProducto) { p in
                            SearchProductoRow(producto: p)
                        }
                    }
                case 1:
                    if clienteVM.clientes.isEmpty {
                        TSEmptyState(icon: "person.2", title: "Sin resultados", subtitle: "Intenta con otro término")
                    } else {
                        ForEach(clienteVM.clientes, id: \.idCliente) { c in
                            SearchClienteRow(cliente: c)
                        }
                    }
                default:
                    if ventaVM.ventas.isEmpty {
                        TSEmptyState(icon: "cart", title: "Sin resultados", subtitle: "Intenta con otro término")
                    } else {
                        ForEach(ventaVM.ventas, id: \.idVenta) { v in
                            SearchVentaRow(venta: v)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
    }

    private func performSearch() {
        switch tab {
        case 0:
            productoVM.searchText = search
            productoVM.buscar()
        case 1:
            clienteVM.searchText = search
            if search.count == 8 && search.allSatisfy(\.isNumber) {
                clienteVM.buscarPorDNI()
            } else {
                clienteVM.buscarPorNombre()
            }
        default:
            ventaVM.searchText = search
            ventaVM.buscarPorCliente()
        }
    }
}

// MARK: - Result Rows
private struct SearchProductoRow: View {
    let producto: Producto
    var body: some View {
        TSCard {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ModuleGradient.productos.gradient)
                        .frame(width: 42, height: 42)
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(producto.nombre ?? "-")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.tsText)
                    Text(producto.categoria ?? "-")
                        .font(.caption)
                        .foregroundColor(.tsSlate)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatCurrency(producto.precio))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.tsIndigo)
                    TSBadge(text: "Stock \(producto.stock)",
                            color: producto.stock <= 5 ? .tsRed : .tsEmerald)
                }
            }
            .padding(12)
        }
    }
}

private struct SearchClienteRow: View {
    let cliente: Cliente
    private var fullName: String { "\(cliente.nombres ?? "") \(cliente.apellidos ?? "")" }
    var body: some View {
        TSCard {
            HStack(spacing: 12) {
                TSAvatar(name: fullName, gradient: .clientes)
                    .scaleEffect(0.9)
                VStack(alignment: .leading, spacing: 3) {
                    Text(fullName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.tsText)
                    Text("DNI: \(cliente.dni ?? "-")")
                        .font(.caption)
                        .foregroundColor(.tsSlate)
                    Text(cliente.correo ?? "-")
                        .font(.system(size: 12))
                        .foregroundColor(.tsSlate)
                        .lineLimit(1)
                }
                Spacer()
                TSBadge(text: cliente.estado ? "Activo" : "Inactivo",
                        color: cliente.estado ? .tsEmerald : .tsRed)
            }
            .padding(12)
        }
    }
}

private struct SearchVentaRow: View {
    let venta: Venta
    private var clienteName: String { "\(venta.cliente?.nombres ?? "") \(venta.cliente?.apellidos ?? "")" }
    var body: some View {
        TSCard {
            HStack(spacing: 12) {
                TSAvatar(name: clienteName, gradient: .ventas)
                    .scaleEffect(0.9)
                VStack(alignment: .leading, spacing: 3) {
                    Text(clienteName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.tsText)
                    Text(venta.producto?.nombre ?? "-")
                        .font(.caption)
                        .foregroundColor(.tsSlate)
                    Text(formatDate(venta.fechaVenta))
                        .font(.system(size: 12))
                        .foregroundColor(.tsSlate)
                }
                Spacer()
                Text(formatCurrency(venta.total))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.tsEmerald)
            }
            .padding(12)
        }
    }
}

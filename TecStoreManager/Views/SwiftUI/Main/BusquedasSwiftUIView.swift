import SwiftUI

struct BusquedasSwiftUIView: View {
    @StateObject private var productoVM = ProductoViewModel()
    @StateObject private var clienteVM  = ClienteViewModel()
    @StateObject private var ventaVM    = VentaViewModel()

    @State private var tab    = 0
    @State private var search = ""

    private var tabTitles = ["Productos", "Clientes", "Ventas"]
    private var tabIcons  = ["shippingbox.fill", "person.2.fill", "chart.bar.fill"]
    private var tabGrads: [NPGradient] = [.productos, .clientes, .ventas]

    var body: some View {
        ZStack {
            Color.npBg.ignoresSafeArea()
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
                            : AnyView(tabGrads[i].start.opacity(0.08))
                    )
                    .clipShape(Capsule())
                    .overlay(
                        tab != i ?
                        Capsule()
                            .stroke(tabGrads[i].start, lineWidth: 1)
                        : nil
                    )
                }
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.npSlate)
            TextField("", text: $search, prompt: Text(placeholder).foregroundColor(.npSlate))
                .font(.system(size: 15))
                .foregroundColor(.npPrimary)
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.npSlate)
                }
            }
        }
        .padding(10)
        .overlay(
            Rectangle()
                .fill(!search.isEmpty ? tabGrads[tab].start : Color.npBorder)
                .frame(height: 1),
            alignment: .bottom
        )
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

    @ViewBuilder
    private var resultsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                switch tab {
                case 0:
                    if productoVM.productos.isEmpty {
                        NPEmptyState(icon: "shippingbox", title: "Sin resultados", subtitle: "Intenta con otro término")
                    } else {
                        ForEach(productoVM.productos, id: \.idProducto) { p in
                            SearchProductoRow(producto: p)
                        }
                    }
                case 1:
                    if clienteVM.clientes.isEmpty {
                        NPEmptyState(icon: "person.2", title: "Sin resultados", subtitle: "Intenta con otro término")
                    } else {
                        ForEach(clienteVM.clientes, id: \.idCliente) { c in
                            SearchClienteRow(cliente: c)
                        }
                    }
                default:
                    if ventaVM.ventas.isEmpty {
                        NPEmptyState(icon: "cart", title: "Sin resultados", subtitle: "Intenta con otro término")
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

private struct SearchProductoRow: View {
    let producto: Producto
    var body: some View {
        NPTopCard(color: .npRose) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(NPGradient.productos.gradient)
                        .frame(width: 42, height: 42)
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(producto.nombre ?? "-")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.npPrimary)
                    Text(producto.categoria ?? "-")
                        .font(.caption)
                        .foregroundColor(.npSlate)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatCurrency(producto.precio))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.npRose)
                    NPBadge(text: "Stock \(producto.stock)",
                            color: producto.stock <= 5 ? .npDanger : .npEmerald)
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
        NPTopCard(color: .npIndigo) {
            HStack(spacing: 12) {
                NPAvatar(name: fullName, gradient: .clientes)
                    .scaleEffect(0.9)
                VStack(alignment: .leading, spacing: 3) {
                    Text(fullName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.npPrimary)
                    Text("DNI: \(cliente.dni ?? "-")")
                        .font(.caption)
                        .foregroundColor(.npSlate)
                    Text(cliente.correo ?? "-")
                        .font(.system(size: 12))
                        .foregroundColor(.npSlate)
                        .lineLimit(1)
                }
                Spacer()
                NPBadge(text: cliente.estado ? "Activo" : "Inactivo",
                        color: cliente.estado ? .npEmerald : .npDanger)
            }
            .padding(12)
        }
    }
}

private struct SearchVentaRow: View {
    let venta: Venta
    private var clienteName: String { "\(venta.cliente?.nombres ?? "") \(venta.cliente?.apellidos ?? "")" }
    private var productosResumen: String {
        let detalles = venta.detalles as? Set<DetalleVenta> ?? []
        let nombres = detalles.compactMap { $0.producto?.nombre }.filter { !$0.isEmpty }
        if nombres.isEmpty { return "-" }
        if nombres.count == 1 { return nombres[0] }
        return "\(nombres[0]) + \(nombres.count - 1) más"
    }
    var body: some View {
        NPTopCard(color: .npEmerald) {
            HStack(spacing: 12) {
                NPAvatar(name: clienteName, gradient: .ventas)
                    .scaleEffect(0.9)
                VStack(alignment: .leading, spacing: 3) {
                    Text(clienteName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.npPrimary)
                    Text(productosResumen)
                        .font(.caption)
                        .foregroundColor(.npSlate)
                    Text(formatDate(venta.fechaVenta))
                        .font(.system(size: 12))
                        .foregroundColor(.npSlate)
                }
                Spacer()
                Text(formatCurrency(venta.total))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.npEmerald)
            }
            .padding(12)
        }
    }
}

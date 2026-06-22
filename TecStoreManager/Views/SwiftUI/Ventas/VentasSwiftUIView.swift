import SwiftUI

// MARK: - Sales List
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
        .background(Color.tsBg.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showForm = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.tsEmerald)
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

    // MARK: - Header compacto
    private var headerBlock: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "cart.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.tsEmerald)
                Text("\(vm.totalVentas()) ventas")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.tsText)
                Spacer()
                Text("\(displayed.count) resultados")
                    .font(.system(size: 12))
                    .foregroundColor(.tsSlate)
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.tsEmerald)
                    .font(.system(size: 15, weight: .medium))
                TextField("Buscar por cliente...", text: $search)
                    .font(.system(size: 15))
                if !search.isEmpty {
                    Button { search = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.tsSlate)
                    }
                }
            }
            .padding(13)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    // MARK: - List
    @ViewBuilder
    private var salesList: some View {
        if displayed.isEmpty {
            TSEmptyState(
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

// MARK: - Venta Card
private struct VentaCard: View {
    let venta: Venta

    private var clienteName: String {
        "\(venta.cliente?.nombres ?? "") \(venta.cliente?.apellidos ?? "")"
    }

    var body: some View {
        TSCard {
            HStack(spacing: 14) {
                TSAvatar(name: clienteName, gradient: .ventas)
                VStack(alignment: .leading, spacing: 4) {
                    Text(clienteName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.tsText)
                    HStack(spacing: 6) {
                        Image(systemName: "shippingbox").font(.caption2).foregroundColor(.tsSlate)
                        Text(venta.producto?.nombre ?? "-")
                            .font(.system(size: 13)).foregroundColor(.tsSlate).lineLimit(1)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "calendar").font(.caption2).foregroundColor(.tsSlate)
                        Text(formatDate(venta.fechaVenta))
                            .font(.system(size: 12)).foregroundColor(.tsSlate)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text(formatCurrency(venta.total))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.tsEmerald)
                    TSBadge(text: "x\(venta.cantidad)", color: .tsBlue)
                }
            }
            .padding(14)
        }
    }
}

// MARK: - Venta Form
struct VentaFormSwiftUIView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm:     VentaViewModel
    @StateObject private var clienteVM  = ClienteViewModel()
    @StateObject private var productoVM = ProductoViewModel()

    @State private var clienteIdx  = 0
    @State private var productoIdx = 0
    @State private var cantidad    = ""
    @State private var error       = ""

    private var activeClientes:  [Cliente]  { clienteVM.clientes.filter  { $0.estado } }
    private var activeProductos: [Producto] { productoVM.productos.filter { $0.estado } }

    private var preview: (subtotal: Double, igv: Double, total: Double) {
        let precio = activeProductos.isEmpty ? 0.0
            : activeProductos[min(productoIdx, activeProductos.count - 1)].precio
        return vm.calcularPreview(cantidadStr: cantidad, precio: precio)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tsBg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle().fill(ModuleGradient.ventas.gradient).frame(width: 80, height: 80)
                            Image(systemName: "cart.badge.plus")
                                .font(.system(size: 34, weight: .bold)).foregroundColor(.white)
                        }
                        .shadow(color: Color.tsEmerald.opacity(0.4), radius: 14, x: 0, y: 6)
                        .padding(.top, 10)

                        TSCard {
                            VStack(spacing: 16) {
                                pickerSection(label: "Cliente", icon: "person.fill") {
                                    if activeClientes.isEmpty {
                                        Text("No hay clientes activos").foregroundColor(.tsRed).font(.caption)
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

                                pickerSection(label: "Producto", icon: "shippingbox.fill") {
                                    if activeProductos.isEmpty {
                                        Text("No hay productos disponibles").foregroundColor(.tsRed).font(.caption)
                                    } else {
                                        Picker("Producto", selection: $productoIdx) {
                                            ForEach(activeProductos.indices, id: \.self) { i in
                                                Text("\(activeProductos[i].nombre ?? "") · Stock: \(activeProductos[i].stock)").tag(i)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .pickerBackground()
                                    }
                                }

                                TSField(icon: "number", placeholder: "Cantidad",
                                        text: $cantidad, keyboardType: .numberPad)

                                if !activeProductos.isEmpty && !cantidad.isEmpty {
                                    pricePreview
                                }

                                TSErrorBanner(message: error)

                                Button("Registrar venta") {
                                    guard !activeClientes.isEmpty, !activeProductos.isEmpty else {
                                        error = "Selecciona cliente y producto"; return
                                    }
                                    if vm.crear(cantidadStr: cantidad,
                                                cliente: activeClientes[clienteIdx],
                                                producto: activeProductos[productoIdx]) {
                                        dismiss()
                                    } else { error = vm.errorMessage }
                                }
                                .buttonStyle(TSPrimaryButtonStyle(gradient: .ventas))
                            }
                            .padding(20)
                        }
                    }
                    .padding(.horizontal, 18).padding(.bottom, 30)
                }
            }
            .navigationTitle("Nueva Venta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
            }
        }
    }

    @ViewBuilder
    private func pickerSection<Content: View>(label: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.tsSlate)
            content()
        }
    }

    private var pricePreview: some View {
        VStack(spacing: 0) {
            Text("Resumen de venta")
                .font(.system(size: 13, weight: .bold)).foregroundColor(.tsSlate)
                .frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 10)
            HStack { Text("Subtotal").foregroundColor(.tsSlate); Spacer()
                Text(formatCurrency(preview.subtotal)).foregroundColor(.tsText).bold() }
            Divider().padding(.vertical, 6)
            HStack { Text("IGV (18%)").foregroundColor(.tsSlate); Spacer()
                Text(formatCurrency(preview.igv)).foregroundColor(.tsAmber).bold() }
            Divider().padding(.vertical, 6)
            HStack {
                Text("TOTAL").font(.system(size: 15, weight: .bold)).foregroundColor(.tsText)
                Spacer()
                Text(formatCurrency(preview.total))
                    .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.tsEmerald)
            }
        }
        .padding(16)
        .background(Color(hex: "#F0FDF4"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.tsEmerald.opacity(0.3), lineWidth: 1))
    }
}

// Helper para estilo de picker
private extension View {
    func pickerBackground() -> some View {
        self
            .padding(12)
            .background(Color(hex: "#F8FAFC"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tsIndigo.opacity(0.18), lineWidth: 1))
    }
}

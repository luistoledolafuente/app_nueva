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

    var body: some View {
        NPTopCard(color: .npEmerald) {
            HStack(spacing: 14) {
                NPAvatar(name: clienteName, gradient: .ventas)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(venta.codigoVenta ?? "---")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.npEmerald)
                        NPBadge(text: "x\(venta.cantidad)", color: .npSecondary)
                    }
                    Text(clienteName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.npPrimary)
                    HStack(spacing: 6) {
                        Image(systemName: "shippingbox").font(.caption2).foregroundColor(.npSlate)
                        Text(venta.producto?.nombre ?? "-")
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
                Color.npBg.ignoresSafeArea()
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [Color.npEmerald, Color(hex: "#047857")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 6)
                    .ignoresSafeArea()
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            ZStack {
                                PolygonShape(sides: 6)
                                    .fill(NPGradient.ventas.gradient)
                                    .frame(width: 80, height: 80)
                                Image(systemName: "cart.badge.plus")
                                    .font(.system(size: 34, weight: .bold)).foregroundColor(.white)
                            }
                            .shadow(color: Color.npEmerald.opacity(0.4), radius: 14, x: 0, y: 6)
                            .padding(.top, 10)

                            NPTopCard(color: .npEmerald) {
                                VStack(spacing: 18) {
                                    Text("Nueva Venta")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.npPrimary)
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

                                    pickerSection(label: "Producto", icon: "shippingbox.fill") {
                                        if activeProductos.isEmpty {
                                            Text("No hay productos disponibles").foregroundColor(.npDanger).font(.caption)
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

                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                            .foregroundColor(.npEmerald)
                                            .font(.system(size: 13))
                                        Text("FV-XXXXX")
                                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                                            .foregroundColor(.npSlate)
                                        Text("• Código auto-generado")
                                            .font(.caption)
                                            .foregroundColor(.npSlate)
                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(Color.npBg)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))

                                    NPField(icon: "number", placeholder: "Cantidad",
                                            text: $cantidad, keyboardType: .numberPad)

                                    if !activeProductos.isEmpty && !cantidad.isEmpty {
                                        pricePreview
                                    }

                                    NPErrorBanner(message: error)

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
                                    .buttonStyle(NPWPButtonStyle(color: .npEmerald))
                                }
                                .padding(20)
                            }
                        }
                        .padding(.horizontal, 18).padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() }
                    .foregroundColor(.npPrimary) }
            }
        }
    }

    @ViewBuilder
    private func pickerSection<Content: View>(label: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.npSlate)
            content()
        }
    }

    private var pricePreview: some View {
        VStack(spacing: 0) {
            Text("Resumen de venta")
                .font(.system(size: 13, weight: .bold)).foregroundColor(.npSlate)
                .frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 10)
            HStack { Text("Subtotal").foregroundColor(.npSlate); Spacer()
                Text(formatCurrency(preview.subtotal)).foregroundColor(.npPrimary).bold() }
            Divider().padding(.vertical, 6)
            HStack { Text("IGV (18%)").foregroundColor(.npSlate); Spacer()
                Text(formatCurrency(preview.igv)).foregroundColor(.npAmber).bold() }
            Divider().padding(.vertical, 6)
            HStack {
                Text("TOTAL").font(.system(size: 15, weight: .bold)).foregroundColor(.npPrimary)
                Spacer()
                Text(formatCurrency(preview.total))
                    .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.npEmerald)
            }
        }
        .padding(16)
        .background(Color.npBg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.npEmerald.opacity(0.3), lineWidth: 1))
    }
}



private extension View {
    func pickerBackground() -> some View {
        self
            .padding(12)
            .background(Color.npBg)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.npBorder, lineWidth: 0.5))
    }
}

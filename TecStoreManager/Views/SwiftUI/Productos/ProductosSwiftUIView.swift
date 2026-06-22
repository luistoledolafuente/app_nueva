import SwiftUI

// MARK: - Products List
struct ProductosSwiftUIView: View {
    @StateObject private var vm       = ProductoViewModel()
    @State private var search         = ""
    @State private var filterLow      = false
    @State private var showForm       = false
    @State private var selected: Producto? = nil
    @State private var toDelete: Producto? = nil
    @State private var showDeleteAlert     = false

    private var displayed: [Producto] {
        let base = filterLow
            ? vm.productos.filter { $0.stock <= 5 }
            : vm.productos
        if search.isEmpty { return base }
        return base.filter {
            ($0.nombre ?? "").localizedCaseInsensitiveContains(search) ||
            ($0.categoria ?? "").localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBlock
            productList
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.tsBg.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { selected = nil; showForm = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.tsIndigo)
                }
            }
        }
        .sheet(isPresented: $showForm, onDismiss: { vm.cargar() }) {
            ProductoFormSwiftUIView(producto: selected, vm: vm)
        }
        .alert("Eliminar producto", isPresented: $showDeleteAlert) {
            Button("Eliminar", role: .destructive) { if let p = toDelete { vm.eliminar(p) } }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("¿Seguro que deseas eliminar \"\(toDelete?.nombre ?? "")\"?")
        }
        .onAppear { vm.cargar() }
    }

    // MARK: - Header compacto
    private var headerBlock: some View {
        VStack(spacing: 8) {
            // Contador
            HStack(spacing: 6) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.tsIndigo)
                Text("\(vm.productos.count) productos")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.tsText)
                Spacer()
                Text("\(displayed.count) resultados")
                    .font(.system(size: 12))
                    .foregroundColor(.tsSlate)
            }

            // Buscador
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.tsIndigo)
                    .font(.system(size: 15, weight: .medium))
                TextField("Buscar por nombre o categoría...", text: $search)
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

            // Filtros
            HStack(spacing: 8) {
                FilterChip(label: "Todos", selected: !filterLow) { filterLow = false }
                FilterChip(label: "⚠ Stock bajo", selected: filterLow, color: .tsRed) { filterLow = true }
                Spacer()
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    // MARK: - List
    @ViewBuilder
    private var productList: some View {
        if displayed.isEmpty {
            TSEmptyState(
                icon: "shippingbox",
                title: "Sin productos",
                subtitle: search.isEmpty ? "Agrega tu primer producto" : "No se encontraron resultados"
            )
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(displayed, id: \.idProducto) { producto in
                        ProductoCard(producto: producto)
                            .onTapGesture { selected = producto; showForm = true }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    toDelete = producto
                                    showDeleteAlert = true
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

// MARK: - Product Card
private struct ProductoCard: View {
    let producto: Producto

    private var stockColor: Color {
        switch producto.stock {
        case ..<6:   return .tsRed
        case 6..<16: return .tsAmber
        default:     return .tsEmerald
        }
    }

    private var stockLabel: String {
        switch producto.stock {
        case ..<6:   return "Bajo"
        case 6..<16: return "Medio"
        default:     return "OK"
        }
    }

    var body: some View {
        TSCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(ModuleGradient.productos.gradient)
                        .frame(width: 52, height: 52)
                    Image(systemName: categoryIcon(producto.categoria ?? ""))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(producto.nombre ?? "-")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.tsText)
                    Text(producto.categoria ?? "-")
                        .font(.caption)
                        .foregroundColor(.tsSlate)
                    Text("Código: \(producto.codigo ?? "-")")
                        .font(.system(size: 11))
                        .foregroundColor(.tsSlate)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(formatCurrency(producto.precio))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.tsIndigo)
                    TSBadge(text: "Stock \(producto.stock)", color: stockColor)
                    TSBadge(text: stockLabel, color: stockColor.opacity(0.75))
                }
            }
            .padding(14)
        }
    }

    private func categoryIcon(_ cat: String) -> String {
        switch cat.lowercased() {
        case "electronica":  return "cpu"
        case "ropa":         return "tshirt"
        case "alimentos":    return "fork.knife"
        case "hogar":        return "house"
        case "deportes":     return "figure.run"
        default:             return "cube.box"
        }
    }
}

// MARK: - Filter Chip
private struct FilterChip: View {
    let label:    String
    let selected: Bool
    var color:    Color = .tsIndigo
    let action:   () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(selected ? .white : color)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(selected ? color : color.opacity(0.1))
                .clipShape(Capsule())
        }
    }
}

// MARK: - Product Form
struct ProductoFormSwiftUIView: View {
    @Environment(\.dismiss) var dismiss
    let producto: Producto?
    let vm:       ProductoViewModel

    @State private var codigo         = ""
    @State private var nombre         = ""
    @State private var categoria      = "Electronica"
    @State private var precio         = ""
    @State private var stock          = ""
    @State private var error          = ""
    @State private var showDeleteAlert = false

    private let categorias = ["Electronica", "Ropa", "Alimentos", "Hogar", "Deportes", "Otros"]
    private var isEditing: Bool { producto != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tsBg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(ModuleGradient.productos.gradient)
                                .frame(width: 80, height: 80)
                            Image(systemName: isEditing ? "pencil" : "plus")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .shadow(color: Color.tsIndigo.opacity(0.4), radius: 14, x: 0, y: 6)
                        .padding(.top, 10)

                        TSCard {
                            VStack(spacing: 16) {
                                sectionLabel("Identificación")
                                TSField(icon: "barcode", placeholder: "Código", text: $codigo)
                                TSField(icon: "tag", placeholder: "Nombre del producto", text: $nombre)

                                sectionLabel("Categoría")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(categorias, id: \.self) { cat in
                                            Button(action: { categoria = cat }) {
                                                Text(cat)
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundColor(categoria == cat ? .white : .tsIndigo)
                                                    .padding(.horizontal, 14).padding(.vertical, 7)
                                                    .background(categoria == cat ? Color.tsIndigo : Color.tsIndigo.opacity(0.1))
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }

                                sectionLabel("Precio y Stock")
                                TSField(icon: "dollarsign.circle", placeholder: "Precio (S/)", text: $precio, keyboardType: .decimalPad)
                                TSField(icon: "archivebox", placeholder: "Stock inicial", text: $stock, keyboardType: .numberPad)

                                TSErrorBanner(message: error)

                                Button(isEditing ? "Guardar cambios" : "Agregar producto") {
                                    guard validate() else { return }
                                    let ok: Bool
                                    if let p = producto {
                                        ok = vm.actualizar(p, codigo: codigo, nombre: nombre, categoria: categoria, precioStr: precio, stockStr: stock)
                                    } else {
                                        ok = vm.crear(codigo: codigo, nombre: nombre, categoria: categoria, precioStr: precio, stockStr: stock)
                                    }
                                    if ok { dismiss() } else { error = vm.errorMessage }
                                }
                                .buttonStyle(TSPrimaryButtonStyle())

                                if isEditing, let p = producto {
                                    Button {
                                        showDeleteAlert = true
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "trash")
                                            Text("Eliminar producto")
                                        }
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.tsRed)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.tsRed.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                    }
                                    .alert("Eliminar producto", isPresented: $showDeleteAlert) {
                                        Button("Eliminar", role: .destructive) {
                                            vm.eliminar(p)
                                            dismiss()
                                        }
                                        Button("Cancelar", role: .cancel) {}
                                    } message: {
                                        Text("¿Estás seguro de que deseas eliminar \"\(p.nombre ?? "")\"? Esta acción no se puede deshacer.")
                                    }
                                }
                            }
                            .padding(20)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle(isEditing ? "Editar Producto" : "Nuevo Producto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .onAppear(perform: loadData)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 13, weight: .semibold)).foregroundColor(.tsSlate)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func loadData() {
        guard let p = producto else { return }
        codigo    = p.codigo    ?? ""
        nombre    = p.nombre    ?? ""
        categoria = p.categoria ?? "Electronica"
        precio    = String(p.precio)
        stock     = String(p.stock)
    }

    private func validate() -> Bool {
        if codigo.isEmpty || nombre.isEmpty || precio.isEmpty || stock.isEmpty {
            error = "Todos los campos son obligatorios"; return false
        }
        return true
    }
}

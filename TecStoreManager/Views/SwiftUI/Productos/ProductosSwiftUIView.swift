import SwiftUI
import PhotosUI

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
        .background(Color.npBg.ignoresSafeArea())
        .navigationTitle("Productos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { selected = nil; showForm = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.npRose)
                }
            }
        }
        .sheet(isPresented: $showForm, onDismiss: { vm.cargar() }) {
            ProductoFormSwiftUIView(producto: selected, vm: vm)
                .id(selected?.idProducto ?? "new")
        }
        .alert("Eliminar producto", isPresented: $showDeleteAlert) {
            Button("Eliminar", role: .destructive) { if let p = toDelete { vm.eliminar(p) } }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("¿Seguro que deseas eliminar \"\(toDelete?.nombre ?? "")\"?")
        }
        .onAppear { vm.cargar() }
    }

    private var headerBlock: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.npRose)
                Text("\(vm.productos.count) productos")
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
                TextField("", text: $search, prompt: Text("Buscar por nombre o categoría...").foregroundColor(.npSlate))
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
                    .fill(!search.isEmpty ? Color.npRose : Color.npBorder)
                    .frame(height: 1),
                alignment: .bottom
            )

            HStack(spacing: 8) {
                NPFilterChip(label: "Todos", selected: !filterLow, color: .npRose) { filterLow = false }
                NPFilterChip(label: "Stock bajo", selected: filterLow, color: .npDanger) { filterLow = true }
                Spacer()
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var productList: some View {
        if displayed.isEmpty {
            NPEmptyState(
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

private struct ProductoCard: View {
    let producto: Producto

    private var stockColor: Color {
        switch producto.stock {
        case ..<6:   return .npDanger
        case 6..<16: return .npAmber
        default:     return .npEmerald
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
        NPTopCard(color: .npRose) {
            HStack(spacing: 14) {
                if let path = producto.imagenPath,
                   let data = try? Data(contentsOf: imageURL(for: path)),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(NPGradient.productos.gradient)
                            .frame(width: 50, height: 50)
                        Image(systemName: categoryIcon(producto.categoria ?? ""))
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(producto.nombre ?? "-")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.npPrimary)
                    Text(producto.categoria ?? "-")
                        .font(.caption)
                        .foregroundColor(.npSlate)
                    Text("Código: \(producto.codigo ?? "-")")
                        .font(.system(size: 11))
                        .foregroundColor(.npSlate)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(formatCurrency(producto.precio))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.npRose)
                    NPBadge(text: "Stock \(producto.stock)", color: stockColor)
                }
            }
            .padding(14)
        }
    }

    private func imageURL(for name: String) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(name)
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
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var productImageData: Data? = nil

    private let categorias = ["Electronica", "Ropa", "Alimentos", "Hogar", "Deportes", "Otros"]
    private var isEditing: Bool { producto != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientGlowBackground(firstColor: Color(hex: "#F43F5E"), secondColor: Color(hex: "#8B5CF6"))
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            ZStack {
                                PolygonShape(sides: 6)
                                    .fill(NPGradient.productos.gradient)
                                    .frame(width: 80, height: 80)
                                Image(systemName: isEditing ? "pencil" : "plus")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .shadow(color: Color(hex: "#F43F5E").opacity(0.3), radius: 12)
                            .padding(.top, 24)
                        }

                        VStack(spacing: 20) {
                            Text(isEditing ? "Editar Producto" : "Nuevo Producto")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack {
                                Image(systemName: "barcode")
                                    .foregroundColor(Color(hex: "#F43F5E"))
                                    .font(.system(size: 14))
                                    .frame(width: 18)
                                Text("Código:")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color.white.opacity(0.6))
                                Text(codigo)
                                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )

                            NPField(icon: "tag",
                                    placeholder: "Nombre del producto",
                                    text: $nombre,
                                    accentColor: .npRose,
                                    textColor: .white,
                                    placeholderColor: Color.white.opacity(0.4),
                                    bgColor: Color.white.opacity(0.06),
                                    borderColor: Color.white.opacity(0.12))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(categorias, id: \.self) { cat in
                                        NPFilterChip(label: cat, selected: categoria == cat, color: .npRose) {
                                            categoria = cat
                                        }
                                    }
                                }
                            }

                            NPField(icon: "dollarsign.circle",
                                    placeholder: "Precio (S/)",
                                    text: $precio,
                                    keyboardType: .decimalPad,
                                    accentColor: .npRose,
                                    textColor: .white,
                                    placeholderColor: Color.white.opacity(0.4),
                                    bgColor: Color.white.opacity(0.06),
                                    borderColor: Color.white.opacity(0.12))

                            NPField(icon: "archivebox",
                                    placeholder: "Stock inicial",
                                    text: $stock,
                                    keyboardType: .numberPad,
                                    accentColor: .npRose,
                                    textColor: .white,
                                    placeholderColor: Color.white.opacity(0.4),
                                    bgColor: Color.white.opacity(0.06),
                                    borderColor: Color.white.opacity(0.12))

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Imagen del producto")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color.white.opacity(0.6))
                                HStack(spacing: 12) {
                                    if let data = productImageData, let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 72, height: 72)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                            )
                                        Button {
                                            productImageData = nil
                                            selectedImage = nil
                                        } label: {
                                            Image(systemName: "trash.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.npDanger)
                                        }
                                    } else {
                                        PhotosPicker(selection: $selectedImage, matching: .images) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                    .frame(width: 72, height: 72)
                                                VStack(spacing: 4) {
                                                    Image(systemName: "camera.fill")
                                                        .font(.system(size: 18))
                                                        .foregroundColor(Color.white.opacity(0.6))
                                                    Text("Foto")
                                                        .font(.system(size: 9))
                                                        .foregroundColor(Color.white.opacity(0.6))
                                                }
                                            }
                                        }
                                    }
                                    Text(productImageData == nil ? "Toca para agregar una foto" : "Foto cargada")
                                        .font(.caption)
                                        .foregroundColor(Color.white.opacity(0.5))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onChange(of: selectedImage) { newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                        productImageData = data
                                    }
                                }
                            }

                            NPErrorBanner(message: error)

                            Button {
                                guard validate() else { return }
                                let ok: Bool
                                let imageName = saveImage()
                                if let p = producto {
                                    ok = vm.actualizar(p, codigo: codigo, nombre: nombre, categoria: categoria, precioStr: precio, stockStr: stock, imagenPath: imageName)
                                } else {
                                    ok = vm.crear(codigo: codigo, nombre: nombre, categoria: categoria, precioStr: precio, stockStr: stock, imagenPath: imageName)
                                }
                                if ok { dismiss() } else { error = vm.errorMessage }
                            } label: {
                                Text(isEditing ? "Guardar cambios" : "Agregar producto")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#F43F5E"), Color(hex: "#BE123C")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color(hex: "#F43F5E").opacity(0.3), radius: 8, x: 0, y: 4)

                            if isEditing, let p = producto {
                                Button {
                                    showDeleteAlert = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "trash")
                                        Text("Eliminar producto")
                                    }
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color(hex: "#EF4444"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(hex: "#EF4444").opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(hex: "#EF4444").opacity(0.2), lineWidth: 1)
                                    )
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
            .onAppear(perform: loadData)
        }
        .preferredColorScheme(.dark)
    }

    private func loadData() {
        if let p = producto {
            codigo    = p.codigo    ?? ""
            nombre    = p.nombre    ?? ""
            categoria = p.categoria ?? "Electronica"
            precio    = String(p.precio)
            stock     = String(p.stock)
            if let path = p.imagenPath, let data = try? Data(contentsOf: imageURL(for: path)) {
                productImageData = data
            }
        } else {
            codigo = vm.generarCodigoProducto()
        }
    }

    private func saveImage() -> String? {
        guard let data = productImageData else { return nil }
        let name = "\(UUID().uuidString).jpg"
        let url = imageURL(for: name)
        try? data.write(to: url)
        return name
    }

    private func imageURL(for name: String) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(name)
    }

    private func validate() -> Bool {
        if codigo.isEmpty || nombre.isEmpty || precio.isEmpty || stock.isEmpty {
            error = "Todos los campos son obligatorios"; return false
        }
        return true
    }
}



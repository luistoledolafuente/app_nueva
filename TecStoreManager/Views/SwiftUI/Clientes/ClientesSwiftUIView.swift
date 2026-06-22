import SwiftUI

// MARK: - Clients List
struct ClientesSwiftUIView: View {
    @StateObject private var vm   = ClienteViewModel()
    @State private var search     = ""
    @State private var filter     = 0
    @State private var showForm   = false
    @State private var selected: Cliente? = nil
    @State private var toDelete:  Cliente? = nil
    @State private var showDeleteAlert     = false

    private var displayed: [Cliente] {
        var list: [Cliente]
        switch filter {
        case 1:  list = vm.clientes.filter { $0.estado }
        case 2:  list = vm.clientes.filter { !$0.estado }
        default: list = vm.clientes
        }
        if search.isEmpty { return list }
        return list.filter {
            let name = "\(($0.nombres ?? "")) \(($0.apellidos ?? ""))"
            return name.localizedCaseInsensitiveContains(search) || ($0.dni ?? "").contains(search)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBlock
            clientList
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.tsBg.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { selected = nil; showForm = true } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 20))
                        .foregroundColor(.tsCyan)
                }
            }
        }
        .sheet(isPresented: $showForm, onDismiss: { vm.cargar() }) {
            ClienteFormSwiftUIView(cliente: selected, vm: vm)
        }
        .alert("Eliminar cliente", isPresented: $showDeleteAlert) {
            Button("Eliminar", role: .destructive) { if let c = toDelete { vm.eliminar(c) } }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("¿Seguro que deseas eliminar a \"\(toDelete?.nombres ?? "")\"?")
        }
        .onAppear { vm.cargar() }
    }

    // MARK: - Header compacto
    private var headerBlock: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.tsCyan)
                Text("\(vm.clientes.count) clientes")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.tsText)
                Spacer()
                Text("\(displayed.count) resultados")
                    .font(.system(size: 12))
                    .foregroundColor(.tsSlate)
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.tsCyan)
                    .font(.system(size: 15, weight: .medium))
                TextField("Buscar por nombre o DNI...", text: $search)
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

            HStack(spacing: 8) {
                FilterChip(label: "Todos",    selected: filter == 0, color: .tsCyan)    { filter = 0 }
                FilterChip(label: "Activos",  selected: filter == 1, color: .tsEmerald) { filter = 1 }
                FilterChip(label: "Inactivos",selected: filter == 2, color: .tsRed)     { filter = 2 }
                Spacer()
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    // MARK: - List
    @ViewBuilder
    private var clientList: some View {
        if displayed.isEmpty {
            TSEmptyState(
                icon: "person.2",
                title: "Sin clientes",
                subtitle: search.isEmpty ? "Agrega tu primer cliente" : "No se encontraron resultados"
            )
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(displayed, id: \.idCliente) { cliente in
                        ClienteCard(cliente: cliente)
                            .onTapGesture { selected = cliente; showForm = true }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    toDelete = cliente; showDeleteAlert = true
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

// MARK: - Client Card
private struct ClienteCard: View {
    let cliente: Cliente
    private var fullName: String { "\(cliente.nombres ?? "") \(cliente.apellidos ?? "")" }

    var body: some View {
        TSCard {
            HStack(spacing: 14) {
                TSAvatar(name: fullName, gradient: .clientes)
                VStack(alignment: .leading, spacing: 4) {
                    Text(fullName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.tsText)
                    HStack(spacing: 6) {
                        Image(systemName: "creditcard").font(.caption2).foregroundColor(.tsSlate)
                        Text(cliente.dni ?? "-").font(.system(size: 13)).foregroundColor(.tsSlate)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "envelope").font(.caption2).foregroundColor(.tsSlate)
                        Text(cliente.correo ?? "-").font(.system(size: 12)).foregroundColor(.tsSlate).lineLimit(1)
                    }
                }
                Spacer()
                TSBadge(text: cliente.estado ? "Activo" : "Inactivo",
                        color: cliente.estado ? .tsEmerald : .tsRed)
            }
            .padding(14)
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

// MARK: - Client Form
struct ClienteFormSwiftUIView: View {
    @Environment(\.dismiss) var dismiss
    let cliente: Cliente?
    let vm:      ClienteViewModel

    @State private var dni            = ""
    @State private var nombres        = ""
    @State private var apellidos      = ""
    @State private var telefono       = ""
    @State private var correo         = ""
    @State private var direccion      = ""
    @State private var estado         = true
    @State private var error          = ""
    @State private var showDeleteAlert = false

    private var isEditing: Bool { cliente != nil }
    private var fullName:  String { "\(nombres) \(apellidos)".trimmingCharacters(in: .whitespaces) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tsBg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        VStack(spacing: 10) {
                            TSAvatar(name: fullName.isEmpty ? "?" : fullName, gradient: .clientes)
                                .scaleEffect(1.6).frame(width: 80, height: 80)
                                .shadow(color: Color.tsCyan.opacity(0.4), radius: 14, x: 0, y: 6)
                            if !fullName.isEmpty {
                                Text(fullName).font(.system(size: 16, weight: .semibold)).foregroundColor(.tsText)
                            }
                        }
                        .padding(.top, 14)

                        TSCard {
                            VStack(spacing: 16) {
                                sectionLabel("Datos personales")
                                TSField(icon: "person.fill", placeholder: "Nombres",   text: $nombres)
                                TSField(icon: "person.fill", placeholder: "Apellidos", text: $apellidos)
                                TSField(icon: "creditcard",  placeholder: "DNI (8 dígitos)", text: $dni, keyboardType: .numberPad)

                                sectionLabel("Contacto")
                                TSField(icon: "phone.fill",   placeholder: "Teléfono",  text: $telefono, keyboardType: .phonePad)
                                TSField(icon: "envelope.fill", placeholder: "Correo",    text: $correo, keyboardType: .emailAddress)
                                TSField(icon: "map.fill",      placeholder: "Dirección", text: $direccion)

                                if isEditing {
                                    HStack {
                                        Image(systemName: "circle.fill")
                                            .foregroundColor(estado ? .tsEmerald : .tsRed)
                                            .font(.system(size: 12))
                                        Text("Estado: \(estado ? "Activo" : "Inactivo")")
                                            .font(.system(size: 15, weight: .medium)).foregroundColor(.tsText)
                                        Spacer()
                                        Toggle("", isOn: $estado).labelsHidden().tint(.tsEmerald)
                                    }
                                    .padding(14)
                                    .background(Color(hex: "#F8FAFC"))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }

                                TSErrorBanner(message: error)

                                Button(isEditing ? "Guardar cambios" : "Registrar cliente") {
                                    let ok: Bool
                                    if let c = cliente {
                                        ok = vm.actualizar(c, dni: dni, nombres: nombres, apellidos: apellidos,
                                                           telefono: telefono, correo: correo, direccion: direccion, estado: estado)
                                    } else {
                                        ok = vm.crear(dni: dni, nombres: nombres, apellidos: apellidos,
                                                      telefono: telefono, correo: correo, direccion: direccion)
                                    }
                                    if ok { dismiss() } else { error = vm.errorMessage }
                                }
                                .buttonStyle(TSPrimaryButtonStyle(gradient: .clientes))

                                if isEditing, let c = cliente {
                                    Button {
                                        showDeleteAlert = true
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "trash")
                                            Text("Eliminar cliente")
                                        }
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.tsRed)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.tsRed.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                    }
                                    .alert("Eliminar cliente", isPresented: $showDeleteAlert) {
                                        Button("Eliminar", role: .destructive) {
                                            vm.eliminar(c)
                                            dismiss()
                                        }
                                        Button("Cancelar", role: .cancel) {}
                                    } message: {
                                        Text("¿Estás seguro de que deseas eliminar a \"\(c.nombres ?? "") \(c.apellidos ?? "")\"? Esta acción no se puede deshacer.")
                                    }
                                }
                            }
                            .padding(20)
                        }
                    }
                    .padding(.horizontal, 18).padding(.bottom, 30)
                }
            }
            .navigationTitle(isEditing ? "Editar Cliente" : "Nuevo Cliente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
            }
            .onAppear {
                guard let c = cliente else { return }
                dni = c.dni ?? ""; nombres = c.nombres ?? ""; apellidos = c.apellidos ?? ""
                telefono = c.telefono ?? ""; correo = c.correo ?? ""; direccion = c.direccion ?? ""
                estado = c.estado
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 13, weight: .semibold)).foregroundColor(.tsSlate)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

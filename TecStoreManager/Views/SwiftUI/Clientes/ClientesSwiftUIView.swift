import SwiftUI

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
        .background(Color.npBg.ignoresSafeArea())
        .navigationTitle("Clientes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { selected = nil; showForm = true } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 20))
                        .foregroundColor(.npIndigo)
                }
            }
        }
        .sheet(isPresented: $showForm, onDismiss: { vm.cargar() }) {
            ClienteFormSwiftUIView(cliente: selected, vm: vm)
                .id(selected?.idCliente?.uuidString ?? "new")
        }
        .alert("Eliminar cliente", isPresented: $showDeleteAlert) {
            Button("Eliminar", role: .destructive) { if let c = toDelete { vm.eliminar(c) } }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("¿Seguro que deseas eliminar a \"\(toDelete?.nombres ?? "")\"?")
        }
        .onAppear { vm.cargar() }
    }

    private var headerBlock: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.npIndigo)
                Text("\(vm.clientes.count) clientes")
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
                TextField("", text: $search, prompt: Text("Buscar por nombre o DNI...").foregroundColor(.npSlate))
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
                    .fill(!search.isEmpty ? Color.npIndigo : Color.npBorder)
                    .frame(height: 1),
                alignment: .bottom
            )

            HStack(spacing: 8) {
                NPFilterChip(label: "Todos",    selected: filter == 0, color: .npIndigo)    { filter = 0 }
                NPFilterChip(label: "Activos",  selected: filter == 1, color: .npEmerald) { filter = 1 }
                NPFilterChip(label: "Inactivos",selected: filter == 2, color: .npDanger)  { filter = 2 }
                Spacer()
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var clientList: some View {
        if displayed.isEmpty {
            NPEmptyState(
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

private struct ClienteCard: View {
    let cliente: Cliente
    private var fullName: String { "\(cliente.nombres ?? "") \(cliente.apellidos ?? "")" }

    var body: some View {
        NPTopCard(color: .npIndigo) {
            HStack(spacing: 14) {
                NPAvatar(name: fullName, gradient: .clientes)
                VStack(alignment: .leading, spacing: 4) {
                    Text(fullName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.npPrimary)
                    HStack(spacing: 6) {
                        Image(systemName: "creditcard").font(.caption2).foregroundColor(.npSlate)
                        Text(cliente.dni ?? "-").font(.system(size: 13)).foregroundColor(.npSlate)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "envelope").font(.caption2).foregroundColor(.npSlate)
                        Text(cliente.correo ?? "-").font(.system(size: 12)).foregroundColor(.npSlate).lineLimit(1)
                    }
                }
                Spacer()
                NPBadge(text: cliente.estado ? "Activo" : "Inactivo",
                        color: cliente.estado ? .npEmerald : .npDanger)
            }
            .padding(14)
        }
    }
}

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
                AmbientGlowBackground(firstColor: Color(hex: "#6366F1"), secondColor: Color(hex: "#8B5CF6"))
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            NPAvatar(name: fullName.isEmpty ? "?" : fullName, gradient: .clientes)
                                .scaleEffect(1.6)
                                .frame(width: 80, height: 80)
                                .shadow(color: Color(hex: "#6366F1").opacity(0.3), radius: 12)
                            
                            if !fullName.isEmpty {
                                Text(fullName)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.top, 24)

                        VStack(spacing: 20) {
                            Text(isEditing ? "Editar Cliente" : "Nuevo Cliente")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            NPField(icon: "creditcard",
                                    placeholder: "DNI (8 dígitos)",
                                    text: $dni,
                                    keyboardType: .numberPad,
                                    accentColor: .npIndigo,
                                    textColor: .white,
                                    placeholderColor: Color.white.opacity(0.4),
                                    bgColor: Color.white.opacity(0.06),
                                    borderColor: Color.white.opacity(0.12))

                            NPField(icon: "person.fill",
                                    placeholder: "Nombres",
                                    text: $nombres,
                                    accentColor: .npIndigo,
                                    textColor: .white,
                                    placeholderColor: Color.white.opacity(0.4),
                                    bgColor: Color.white.opacity(0.06),
                                    borderColor: Color.white.opacity(0.12))

                            NPField(icon: "person.fill",
                                    placeholder: "Apellidos",
                                    text: $apellidos,
                                    accentColor: .npIndigo,
                                    textColor: .white,
                                    placeholderColor: Color.white.opacity(0.4),
                                    bgColor: Color.white.opacity(0.06),
                                    borderColor: Color.white.opacity(0.12))

                            NPField(icon: "phone.fill",
                                    placeholder: "Teléfono",
                                    text: $telefono,
                                    keyboardType: .phonePad,
                                    accentColor: .npIndigo,
                                    textColor: .white,
                                    placeholderColor: Color.white.opacity(0.4),
                                    bgColor: Color.white.opacity(0.06),
                                    borderColor: Color.white.opacity(0.12))

                            NPField(icon: "envelope.fill",
                                    placeholder: "Correo",
                                    text: $correo,
                                    keyboardType: .emailAddress,
                                    accentColor: .npIndigo,
                                    textColor: .white,
                                    placeholderColor: Color.white.opacity(0.4),
                                    bgColor: Color.white.opacity(0.06),
                                    borderColor: Color.white.opacity(0.12))

                            NPField(icon: "map.fill",
                                    placeholder: "Dirección",
                                    text: $direccion,
                                    accentColor: .npIndigo,
                                    textColor: .white,
                                    placeholderColor: Color.white.opacity(0.4),
                                    bgColor: Color.white.opacity(0.06),
                                    borderColor: Color.white.opacity(0.12))

                            if isEditing {
                                HStack {
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(estado ? .npEmerald : .npDanger)
                                        .font(.system(size: 10))
                                    Text("Estado: \(estado ? "Activo" : "Inactivo")")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Toggle("", isOn: $estado)
                                        .labelsHidden()
                                        .tint(Color(hex: "#10B981"))
                                }
                                .padding(14)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                            }

                            NPErrorBanner(message: error)

                            Button {
                                let ok: Bool
                                if let c = cliente {
                                    ok = vm.actualizar(c, dni: dni, nombres: nombres, apellidos: apellidos,
                                                       telefono: telefono, correo: correo, direccion: direccion, estado: estado)
                                } else {
                                    ok = vm.crear(dni: dni, nombres: nombres, apellidos: apellidos,
                                                  telefono: telefono, correo: correo, direccion: direccion)
                                }
                                if ok { dismiss() } else { error = vm.errorMessage }
                            } label: {
                                Text(isEditing ? "Guardar cambios" : "Registrar cliente")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#6366F1"), Color(hex: "#4F46E5")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color(hex: "#6366F1").opacity(0.3), radius: 8, x: 0, y: 4)

                            if isEditing, let c = cliente {
                                Button {
                                    showDeleteAlert = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "trash")
                                        Text("Eliminar cliente")
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
            .onAppear {
                guard let c = cliente else { return }
                dni = c.dni ?? ""; nombres = c.nombres ?? ""; apellidos = c.apellidos ?? ""
                telefono = c.telefono ?? ""; correo = c.correo ?? ""; direccion = c.direccion ?? ""
                estado = c.estado
            }
        }
        .preferredColorScheme(.dark)
    }

}

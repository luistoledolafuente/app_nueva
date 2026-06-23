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
    @State private var isConsultandoDNI = false
    @State private var consultaExitosa = false

    private var isEditing: Bool { cliente != nil }
    private var fullName:  String { "\(nombres) \(apellidos)".trimmingCharacters(in: .whitespaces) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.npBg.ignoresSafeArea()
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [Color.npIndigo, Color(hex: "#4338CA")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 6)
                    .ignoresSafeArea()

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            VStack(spacing: 10) {
                                NPAvatar(name: fullName.isEmpty ? "?" : fullName, gradient: .clientes)
                                    .scaleEffect(1.6).frame(width: 80, height: 80)
                                    .shadow(color: Color.npSecondary.opacity(0.4), radius: 14, x: 0, y: 6)
                                if !fullName.isEmpty {
                                    Text(fullName).font(.system(size: 16, weight: .semibold)).foregroundColor(.npPrimary)
                                }
                            }
                            .padding(.top, 14)

                            NPTopCard(color: .npIndigo) {
                                VStack(spacing: 18) {
                                    Text(isEditing ? "Editar Cliente" : "Nuevo Cliente")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.npPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    HStack(spacing: 8) {
                                        NPField(icon: "creditcard",  placeholder: "DNI (8 dígitos)", text: $dni, keyboardType: .numberPad)
                                        if isConsultandoDNI {
                                            ProgressView()
                                                .tint(.npIndigo)
                                        } else if consultaExitosa && dni.count == 8 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.npSuccess)
                                                .font(.system(size: 20))
                                        }
                                    }
                                    .onChange(of: dni) { newValue in
                                        if newValue.count == 8 && !isEditing {
                                            Task { await consultarDNI() }
                                        } else {
                                            consultaExitosa = false
                                        }
                                    }
                                    NPField(icon: "person.fill", placeholder: "Nombres",   text: $nombres)
                                    NPField(icon: "person.fill", placeholder: "Apellidos", text: $apellidos)
                                    NPField(icon: "phone.fill",   placeholder: "Teléfono",  text: $telefono, keyboardType: .phonePad)
                                    NPField(icon: "envelope.fill", placeholder: "Correo",    text: $correo, keyboardType: .emailAddress)
                                    NPField(icon: "map.fill",      placeholder: "Dirección", text: $direccion)

                                    if isEditing {
                                        HStack {
                                            Image(systemName: "circle.fill")
                                                .foregroundColor(estado ? .npEmerald : .npDanger)
                                                .font(.system(size: 12))
                                            Text("Estado: \(estado ? "Activo" : "Inactivo")")
                                                .font(.system(size: 15, weight: .medium)).foregroundColor(.npPrimary)
                                            Spacer()
                                            Toggle("", isOn: $estado).labelsHidden().tint(.npEmerald)
                                        }
                                        .padding(14)
                                        .background(Color(hex: "#FAFAF9"))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.npBorder, lineWidth: 0.5))
                                    }

                                    NPErrorBanner(message: error)

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
                                    .buttonStyle(NPWPButtonStyle(color: .npIndigo))

                                    if isEditing, let c = cliente {
                                        Button {
                                            showDeleteAlert = true
                                        } label: {
                                            HStack(spacing: 8) {
                                                Image(systemName: "trash")
                                                Text("Eliminar cliente")
                                            }
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.npDanger)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(Color.npDanger.opacity(0.06))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.npDanger.opacity(0.2), lineWidth: 0.5))
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
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() }
                    .foregroundColor(.npPrimary) }
            }
            .onAppear {
                guard let c = cliente else { return }
                dni = c.dni ?? ""; nombres = c.nombres ?? ""; apellidos = c.apellidos ?? ""
                telefono = c.telefono ?? ""; correo = c.correo ?? ""; direccion = c.direccion ?? ""
                estado = c.estado
            }
        }
    }

    private func consultarDNI() async {
        guard dni.count == 8 else { return }
        isConsultandoDNI = true
        error = ""
        do {
            let data = try await ReniecService.shared.consultarDNI(dni)
            withAnimation {
                nombres = data.nombres.capitalized
                apellidos = "\(data.apellidoPaterno.capitalized) \(data.apellidoMaterno.capitalized)".trimmingCharacters(in: .whitespaces)
                consultaExitosa = true
            }
        } catch let serviceError {
            error = serviceError.localizedDescription
            consultaExitosa = false
        }
        isConsultandoDNI = false
    }
}

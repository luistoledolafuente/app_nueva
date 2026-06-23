import SwiftUI

struct MenuItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let gradient: NPGradient
    let destination: AnyView
}

struct MenuSwiftUIView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showLogout = false

    private var items: [MenuItem] {
        [
            MenuItem(title: "Productos",      subtitle: "Inventario",    icon: "shippingbox.fill",           gradient: .productos,     destination: AnyView(ProductosSwiftUIView())),
            MenuItem(title: "Clientes",       subtitle: "Base de datos", icon: "person.2.fill",              gradient: .clientes,      destination: AnyView(ClientesSwiftUIView())),
            MenuItem(title: "Ventas",         subtitle: "Transacciones", icon: "chart.bar.fill",             gradient: .ventas,        destination: AnyView(VentasSwiftUIView())),
            MenuItem(title: "Búsquedas",      subtitle: "Encontrar",     icon: "magnifyingglass.circle.fill", gradient: .busquedas,     destination: AnyView(BusquedasSwiftUIView())),
            MenuItem(title: "Mapa",           subtitle: "Ubicaciones",   icon: "map.fill",                   gradient: .mapa,          destination: AnyView(MapaSwiftUIView())),
            MenuItem(title: "Reportes",       subtitle: "Estadísticas",  icon: "chart.pie.fill",             gradient: .reportes,      destination: AnyView(ReportesSwiftUIView())),
            MenuItem(title: "Configuración",  subtitle: "Ajustes",       icon: "gearshape.2.fill",           gradient: .configuracion, destination: AnyView(ConfiguracionSwiftUIView())),
            MenuItem(title: "Acerca de",      subtitle: "Información",   icon: "info.circle.fill",           gradient: .acercaDe,      destination: AnyView(AcercaDeSwiftUIView())),
        ]
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ZStack {
            Color.npBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    headerSection
                    modulesGrid
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
            }
        }
        .navigationTitle("Menú completo")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Cerrar sesión", isPresented: $showLogout) {
            Button("Cerrar sesión", role: .destructive) {
                withAnimation { authVM.logout() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("¿Estás seguro de que deseas cerrar sesión?")
        }
    }

    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(NPGradient.dashboard.gradient)
                    .frame(width: 52, height: 52)
                Text(initials)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(authVM.usuarioActual?.nombreCompleto ?? "Usuario")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.npPrimary)
                MPBadge(text: "Admin", color: .npSecondary)
            }
            Spacer()

            Button {
                showLogout = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Salir")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.npAccent)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.npAccent, lineWidth: 1)
                )
            }
        }
        .padding(.top, 16)
    }

    private var modulesGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(items, id: \.id) { item in
                NavigationLink(destination: item.destination) {
                    MenuCard(item: item)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var initials: String {
        let name = authVM.usuarioActual?.nombreCompleto ?? "U"
        let parts = name.split(separator: " ")
        let chars = parts.prefix(2).compactMap { $0.first.map { String($0) } }
        return chars.joined().uppercased()
    }
}

// MARK: - Menu Card (sin DragGesture)
private struct MenuCard: View {
    let item: MenuItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(item.gradient.gradient)
                    .frame(width: 52, height: 52)
                Image(systemName: item.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: item.gradient.start.opacity(0.3), radius: 6, x: 0, y: 3)

            Spacer()

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.npPrimary)
                Text(item.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.npMuted)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .background(Color.npCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

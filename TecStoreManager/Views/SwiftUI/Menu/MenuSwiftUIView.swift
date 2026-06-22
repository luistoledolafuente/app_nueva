import SwiftUI

private struct MenuItem: Identifiable {
    let id         = UUID()
    let title:     String
    let subtitle:  String
    let icon:      String
    let gradient:  ModuleGradient
    let destination: AnyView
}

struct MenuSwiftUIView: View {
    @EnvironmentObject var authVM:  AuthViewModel
    @State private var showLogout  = false
    @State private var appeared    = false

    private var items: [MenuItem] {
        [
            MenuItem(title: "Productos",      subtitle: "Inventario",    icon: "shippingbox.fill",      gradient: .productos,     destination: AnyView(ProductosSwiftUIView())),
            MenuItem(title: "Clientes",       subtitle: "Base de datos", icon: "person.2.fill",         gradient: .clientes,      destination: AnyView(ClientesSwiftUIView())),
            MenuItem(title: "Ventas",         subtitle: "Transacciones", icon: "chart.bar.fill",        gradient: .ventas,        destination: AnyView(VentasSwiftUIView())),
            MenuItem(title: "Búsquedas",      subtitle: "Encontrar",     icon: "magnifyingglass.circle.fill", gradient: .busquedas, destination: AnyView(BusquedasSwiftUIView())),
            MenuItem(title: "Mapa",           subtitle: "Ubicaciones",   icon: "map.fill",              gradient: .mapa,          destination: AnyView(MapaSwiftUIView())),
            MenuItem(title: "Reportes",       subtitle: "Estadísticas",  icon: "chart.pie.fill",        gradient: .reportes,      destination: AnyView(ReportesSwiftUIView())),
            MenuItem(title: "Configuración",  subtitle: "Ajustes",       icon: "gearshape.2.fill",      gradient: .configuracion, destination: AnyView(ConfiguracionSwiftUIView())),
            MenuItem(title: "Acerca de",      subtitle: "Información",   icon: "info.circle.fill",      gradient: .acercaDe,      destination: AnyView(AcercaDeSwiftUIView())),
        ]
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tsBg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        modulesGrid
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Cerrar sesión", isPresented: $showLogout) {
            Button("Cerrar sesión", role: .destructive) {
                withAnimation { authVM.logout() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("¿Estás seguro de que deseas cerrar sesión?")
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bienvenido 👋")
                    .font(.system(size: 14))
                    .foregroundColor(.tsSlate)
                Text(authVM.usuarioActual?.nombreCompleto ?? "Usuario")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.tsText)
                    .lineLimit(1)
                Text("TecStore Manager")
                    .font(.caption)
                    .foregroundColor(.tsSlate)
            }
            Spacer()
            Button {
                showLogout = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.tsRed.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.tsRed)
                }
            }
        }
        .padding(.top, 18)
    }

    // MARK: - Grid
    private var modulesGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                NavigationLink(destination: item.destination) {
                    MenuCard(item: item, delay: Double(index) * 0.06)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Menu Card
private struct MenuCard: View {
    let item:  MenuItem
    let delay: Double

    @State private var appeared  = false
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Icon badge
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 58, height: 58)
                Image(systemName: item.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(item.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.75))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .background(item.gradient.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: item.gradient.start.opacity(0.35), radius: 12, x: 0, y: 6)
        .scaleEffect(appeared ? (isPressed ? 0.95 : 1.0) : 0.85)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.72).delay(delay)) {
                appeared = true
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeInOut(duration: 0.12)) { isPressed = true } }
                .onEnded   { _ in withAnimation(.spring(response: 0.3))    { isPressed = false } }
        )
    }
}

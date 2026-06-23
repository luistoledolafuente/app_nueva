import SwiftUI
import Charts

struct DashboardSwiftUIView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var ventaVM    = VentaViewModel()
    @StateObject private var clienteVM  = ClienteViewModel()
    @StateObject private var productoVM = ProductoViewModel()

    @State private var showLogout = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.npBg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        headerSection
                        statsRow
                        chartSection
                        quickActions
                        recentSales
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                ventaVM.cargar()
                clienteVM.cargar()
                productoVM.cargar()
            }
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
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(NPGradient.dashboard.gradient)
                    .frame(width: 46, height: 46)
                Text(initials)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Dashboard")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.npMuted)
                Text(authVM.usuarioActual?.nombreCompleto ?? "Usuario")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.npPrimary)
            }
            Spacer()

            Button {
                showLogout = true
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.npAccent)
                    .padding(10)
                    .background(Color.npAccent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Stats Row
    private var statsRow: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(value: "\(ventaVM.totalVentas())", label: "Ventas", color: .npEmerald, icon: "cart.fill")
            StatCard(value: "\(clienteVM.totalClientes())", label: "Clientes", color: .npIndigo, icon: "person.2.fill")
            StatCard(value: "\(productoVM.productos.count)", label: "Productos", color: .npRose, icon: "shippingbox.fill")
        }
    }

    // MARK: - Chart
    private var chartSection: some View {
        MPCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Ventas del mes", systemImage: "chart.bar.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.npPrimary)
                    Spacer()
                    MPBadge(text: "\(ventaVM.totalVentas()) ventas", color: .npSecondary)
                }

                let data = ventasPorDia()
                if data.isEmpty {
                    Text("Aún no hay ventas este mes")
                        .font(.subheadline)
                        .foregroundColor(.npMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                } else {
                    Chart(data, id: \.day) { item in
                        BarMark(
                            x: .value("Día", item.day),
                            y: .value("Ventas", item.count)
                        )
                        .foregroundStyle(NPGradient.ventas.gradient)
                        .cornerRadius(4)
                    }
                    .frame(height: 160)
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 7)) { _ in
                            AxisValueLabel(format: .dateTime.day(), centered: true)
                                .font(.system(size: 9))
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .font(.system(size: 9))
                        }
                    }
                }

                HStack {
                    StatLine(label: "Total mes", value: formatCurrency(ventasDelMes()))
                    Spacer()
                    StatLine(label: "Promedio/día", value: formatCurrency(promedioDiario()))
                }
            }
            .padding(16)
        }
    }

    // MARK: - Quick Actions
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Acceso rápido")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.npPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                QuickActionButton(title: "Productos", icon: "shippingbox.fill", gradient: .productos, destination: ProductosSwiftUIView())
                QuickActionButton(title: "Clientes", icon: "person.2.fill", gradient: .clientes, destination: ClientesSwiftUIView())
                QuickActionButton(title: "Ventas", icon: "chart.bar.fill", gradient: .ventas, destination: VentasSwiftUIView())
                QuickActionButton(title: "Menú completo", icon: "square.grid.2x2.fill", gradient: .dashboard, destination: MenuSwiftUIView())
            }
        }
    }

    // MARK: - Recent Sales
    private var recentSales: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Últimas ventas")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.npPrimary)

            if ventaVM.ventas.isEmpty {
                MPEmptyState(icon: "cart", title: "Sin ventas", subtitle: "Registra tu primera venta")
            } else {
                ForEach(Array(ventaVM.ventas.prefix(5)), id: \.idVenta) { venta in
                    RecentSaleRow(venta: venta)
                }
            }
        }
    }

    // MARK: - Helpers
    private var initials: String {
        let name = authVM.usuarioActual?.nombreCompleto ?? "U"
        let parts = name.split(separator: " ")
        let chars = parts.prefix(2).compactMap { $0.first.map { String($0) } }
        return chars.joined().uppercased()
    }

    private func ventasDelMes() -> Double {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        let end = Date()
        return ventaVM.ventas
            .filter { ($0.fechaVenta ?? Date()) >= start && ($0.fechaVenta ?? Date()) <= end }
            .reduce(0) { $0 + $1.total }
    }

    private func promedioDiario() -> Double {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: Date())
        guard day > 0 else { return 0 }
        return ventasDelMes() / Double(day)
    }

    private func ventasPorDia() -> [(day: Date, count: Int)] {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        let ventasMes = ventaVM.ventas.filter { ($0.fechaVenta ?? Date()) >= start }
        var grouped: [Date: Int] = [:]
        for venta in ventasMes {
            guard let fecha = venta.fechaVenta else { continue }
            let day = calendar.startOfDay(for: fecha)
            grouped[day, default: 0] += 1
        }
        return grouped.map { ($0.key, $0.value) }.sorted { $0.day < $1.day }
    }
}

// MARK: - Stat Card
private struct StatCard: View {
    let value: String
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        MPCard {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundColor(color)
                }
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.npPrimary)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.npMuted)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Stat Line
private struct StatLine: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.npPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.npMuted)
        }
    }
}

// MARK: - Quick Action Button
private struct QuickActionButton<Destination: View>: View {
    let title: String
    let icon: String
    let gradient: NPGradient
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(gradient.gradient)
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.npPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.npMuted)
            }
            .padding(12)
            .background(Color.npCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recent Sale Row
private struct RecentSaleRow: View {
    let venta: Venta

    private var clienteName: String {
        "\(venta.cliente?.nombres ?? "") \(venta.cliente?.apellidos ?? "")"
    }

    private var productosResumen: String {
        let detalles = venta.detalles as? Set<DetalleVenta> ?? []
        let nombres = detalles.compactMap { $0.producto?.nombre }.filter { !$0.isEmpty }
        if nombres.isEmpty { return "-" }
        if nombres.count == 1 { return nombres[0] }
        return "\(nombres[0]) + \(nombres.count - 1) más"
    }

    var body: some View {
        MPCard {
            HStack(spacing: 12) {
                MPAvatar(name: clienteName, gradient: .ventas)
                VStack(alignment: .leading, spacing: 2) {
                    Text(clienteName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.npPrimary)
                    Text(productosResumen)
                        .font(.caption)
                        .foregroundColor(.npMuted)
                }
                Spacer()
                Text(formatCurrency(venta.total))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.npEmerald)
            }
            .padding(12)
        }
    }
}

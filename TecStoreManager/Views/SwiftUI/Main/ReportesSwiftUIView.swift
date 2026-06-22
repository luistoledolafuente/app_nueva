import SwiftUI

struct ReportesSwiftUIView: View {
    @StateObject private var ventaVM    = VentaViewModel()
    @StateObject private var clienteVM  = ClienteViewModel()
    @StateObject private var productoVM = ProductoViewModel()

    private var totalVendido: Double  { ventaVM.montoTotalVendido() }
    private var igvTotal:     Double  { totalVendido / 1.18 * 0.18 }
    private var subtotalNet:  Double  { totalVendido - igvTotal }

    private let cols = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ZStack {
            Color.tsBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    revenueHero
                    statsGrid
                    fiscalCard
                    lowStockCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Reportes")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            ventaVM.cargar()
            clienteVM.cargar()
            productoVM.cargar()
        }
    }

    // MARK: - Revenue Hero
    private var revenueHero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(ModuleGradient.ventas.gradient)
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.06))
                .padding(6)

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.pie.fill")
                            .foregroundColor(.white.opacity(0.8))
                        Text("MONTO TOTAL")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .tracking(1.5)
                    }
                    Text(formatCurrency(totalVendido))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("\(ventaVM.totalVentas()) ventas registradas")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 72, height: 72)
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.system(size: 38))
                        .foregroundColor(.white)
                }
            }
            .padding(22)
        }
        .shadow(color: Color.tsEmerald.opacity(0.35), radius: 18, x: 0, y: 8)
    }

    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: cols, spacing: 14) {
            StatCard(icon: "cart.fill",
                     value: "\(ventaVM.totalVentas())",
                     label: "Ventas",
                     gradient: .ventas)
            StatCard(icon: "person.2.fill",
                     value: "\(clienteVM.totalClientes())",
                     label: "Clientes",
                     gradient: .clientes)
            StatCard(icon: "shippingbox.fill",
                     value: "\(productoVM.productos.count)",
                     label: "Productos",
                     gradient: .productos)
            StatCard(icon: "exclamationmark.triangle.fill",
                     value: "\(productoVM.productos.filter { $0.stock <= 5 }.count)",
                     label: "Stock bajo",
                     gradient: .mapa)
        }
    }

    // MARK: - Fiscal Card
    private var fiscalCard: some View {
        TSCard {
            VStack(spacing: 16) {
                HStack {
                    Label("Resumen fiscal", systemImage: "doc.text.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.tsText)
                    Spacer()
                    TSBadge(text: "IGV 18%", color: .tsAmber)
                }

                FiscalRow(label: "Subtotal (sin IGV)", value: formatCurrency(subtotalNet), color: .tsSlate)
                Divider()
                FiscalRow(label: "IGV (18%)", value: formatCurrency(igvTotal), color: .tsAmber)
                Divider()
                FiscalRow(label: "Total bruto", value: formatCurrency(totalVendido), color: .tsEmerald)
                    .font(.system(size: 16, weight: .bold))
            }
            .padding(18)
        }
    }

    // MARK: - Low Stock Card
    private var lowStockCard: some View {
        TSCard {
            VStack(spacing: 14) {
                HStack {
                    Label("Menor stock", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.tsText)
                    Spacer()
                }

                if let prod = productoVM.productoMenorStock() {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.tsRed.opacity(0.12))
                                .frame(width: 50, height: 50)
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.tsRed)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(prod.nombre ?? "-")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.tsText)
                            Text(prod.categoria ?? "-")
                                .font(.caption)
                                .foregroundColor(.tsSlate)
                        }
                        Spacer()
                        TSBadge(text: "Stock: \(prod.stock)", color: .tsRed)
                    }
                } else {
                    Text("No hay productos registrados")
                        .font(.subheadline)
                        .foregroundColor(.tsSlate)
                }
            }
            .padding(18)
        }
    }
}

private struct FiscalRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.tsSlate)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

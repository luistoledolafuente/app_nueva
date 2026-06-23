import SwiftUI
import PDFKit

struct ReportesSwiftUIView: View {
    @StateObject private var ventaVM    = VentaViewModel()
    @StateObject private var clienteVM  = ClienteViewModel()
    @StateObject private var productoVM = ProductoViewModel()

    @State private var showShareSheet = false
    @State private var pdfURL: URL? = nil

    private var totalVendido: Double  { ventaVM.montoTotalVendido() }
    private var igvTotal:     Double  { totalVendido / 1.18 * 0.18 }
    private var subtotalNet:  Double  { totalVendido - igvTotal }

    private let cols = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ZStack {
            Color.npBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    revenueHero
                    actionButtons
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
        .sheet(item: $pdfURL) { url in
            ShareSheet(items: [url])
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                exportPDF()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.richtext")
                        .font(.system(size: 15, weight: .bold))
                    Text("Exportar PDF")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(NPGradient.reportes.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.npAccent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }

    private var revenueHero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(NPGradient.ventas.gradient)

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
                        .frame(width: 68, height: 68)
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
            }
            .padding(20)
        }
        .shadow(color: Color.npEmerald.opacity(0.3), radius: 14, x: 0, y: 6)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: cols, spacing: 14) {
            StatCardNP(icon: "cart.fill",
                      value: "\(ventaVM.totalVentas())",
                      label: "Ventas",
                      gradient: .ventas)
            StatCardNP(icon: "person.2.fill",
                      value: "\(clienteVM.totalClientes())",
                      label: "Clientes",
                      gradient: .clientes)
            StatCardNP(icon: "shippingbox.fill",
                      value: "\(productoVM.productos.count)",
                      label: "Productos",
                      gradient: .productos)
            StatCardNP(icon: "exclamationmark.triangle.fill",
                      value: "\(productoVM.productos.filter { $0.stock <= 5 }.count)",
                      label: "Stock bajo",
                      gradient: .mapa)
        }
    }

    private var fiscalCard: some View {
        NPTopCard(color: .npAmber) {
            VStack(spacing: 14) {
                HStack {
                    Label("Resumen fiscal", systemImage: "doc.text.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.npPrimary)
                    Spacer()
                    NPBadge(text: "IGV 18%", color: .npAmber)
                }

                FiscalRowNP(label: "Subtotal (sin IGV)", value: formatCurrency(subtotalNet), color: .npSlate)
                Divider()
                FiscalRowNP(label: "IGV (18%)", value: formatCurrency(igvTotal), color: .npAmber)
                Divider()
                FiscalRowNP(label: "Total bruto", value: formatCurrency(totalVendido), color: .npEmerald)
                    .font(.system(size: 16, weight: .bold))
            }
            .padding(18)
        }
    }

    private var lowStockCard: some View {
        NPTopCard(color: .npDanger) {
            VStack(spacing: 14) {
                HStack {
                    Label("Menor stock", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.npPrimary)
                    Spacer()
                }

                if let prod = productoVM.productoMenorStock() {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.npDanger.opacity(0.12))
                                .frame(width: 48, height: 48)
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.npDanger)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(prod.nombre ?? "-")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.npPrimary)
                            Text(prod.categoria ?? "-")
                                .font(.caption)
                                .foregroundColor(.npSlate)
                        }
                        Spacer()
                        NPBadge(text: "Stock: \(prod.stock)", color: .npDanger)
                    }
                } else {
                    Text("No hay productos registrados")
                        .font(.subheadline)
                        .foregroundColor(.npSlate)
                }
            }
            .padding(18)
        }
    }

    // MARK: - PDF Export
    private func exportPDF() {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let context = ctx.cgContext

            let title = "Reporte TecStore Manager"
            let date = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)

            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 22),
                .foregroundColor: UIColor(hex: "#1E293B")
            ]
            title.draw(at: CGPoint(x: 40, y: 40), withAttributes: titleAttrs)

            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor(hex: "#78716C")
            ]
            date.draw(at: CGPoint(x: 40, y: 72), withAttributes: dateAttrs)

            var y: CGFloat = 110
            let items: [(String, String, UIColor)] = [
                ("Ventas totales", "\(ventaVM.totalVentas())", UIColor(hex: "#10B981")),
                ("Clientes", "\(clienteVM.totalClientes())", UIColor(hex: "#6366F1")),
                ("Productos", "\(productoVM.productos.count)", UIColor(hex: "#F43F5E")),
                ("Stock bajo", "\(productoVM.productos.filter { $0.stock <= 5 }.count)", UIColor(hex: "#EF4444")),
                ("", "", .clear),
                ("Monto total", formatCurrency(totalVendido), UIColor(hex: "#10B981")),
                ("IGV (18%)", formatCurrency(igvTotal), UIColor(hex: "#F59E0B")),
                ("Subtotal", formatCurrency(subtotalNet), UIColor(hex: "#78716C")),
            ]

            for (label, value, color) in items {
                if label.isEmpty {
                    y += 8
                    continue
                }
                let labelAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor(hex: "#78716C")
                ]
                label.draw(at: CGPoint(x: 40, y: y), withAttributes: labelAttrs)

                let valAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 14),
                    .foregroundColor: color
                ]
                value.draw(at: CGPoint(x: 300, y: y), withAttributes: valAttrs)
                y += 30
            }

            // Footer
            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 10),
                .foregroundColor: UIColor(hex: "#78716C")
            ]
            let footer = "Generado por TecStore Manager v1.0.0"
            footer.draw(at: CGPoint(x: 40, y: y + 40), withAttributes: footerAttrs)
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Reporte_\(Int(Date().timeIntervalSince1970)).pdf")
        try? data.write(to: tempURL)
        pdfURL = tempURL
    }
}

private struct StatCardNP: View {
    let icon:     String
    let value:    String
    let label:    String
    let gradient: NPGradient

    var body: some View {
        NPTopCard(color: gradient.start) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(gradient.gradient)
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(value)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.npPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.npSlate)
                        .lineLimit(1)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct FiscalRowNP: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.npSlate)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

// MARK: - ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}

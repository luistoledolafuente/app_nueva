import SwiftUI

struct VentaDetailView: View {
    let venta: Venta

    private var clienteName: String {
        "\(venta.cliente?.nombres ?? "") \(venta.cliente?.apellidos ?? "")"
    }

    private var detalles: [DetalleVenta] {
        (venta.detalles as? Set<DetalleVenta>)?
            .sorted { ($0.producto?.nombre ?? "") < ($1.producto?.nombre ?? "") } ?? []
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Cliente card
                MPCard {
                    HStack(spacing: 14) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.npIndigo)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(clienteName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.npPrimary)
                            Text("DNI: \(venta.cliente?.dni ?? "-")")
                                .font(.system(size: 13))
                                .foregroundColor(.npSlate)
                            Text(formatDate(venta.fechaVenta))
                                .font(.system(size: 12))
                                .foregroundColor(.npSlate)
                        }
                        Spacer()
                    }
                    .padding(16)
                }

                // Productos
                Text("PRODUCTOS".uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.npSlate)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)

                ForEach(detalles, id: \.idDetalle) { detalle in
                    MPCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(detalle.producto?.nombre ?? "-")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.npPrimary)
                                HStack(spacing: 4) {
                                    Text("S/ \(String(format: "%.2f", detalle.precioUnitario)) c/u")
                                    Text("×")
                                    Text("\(detalle.cantidad)")
                                }
                                .font(.system(size: 12))
                                .foregroundColor(.npSlate)
                                if detalle.descuento > 0 {
                                    Text("Descuento: S/ \(String(format: "%.2f", detalle.descuento))")
                                        .font(.system(size: 11))
                                        .foregroundColor(.npDanger)
                                }
                            }
                            Spacer()
                            Text("S/ \(String(format: "%.2f", detalle.subtotal))")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.npIndigo)
                        }
                        .padding(14)
                    }
                }

                // Resumen
                MPCard {
                    VStack(spacing: 10) {
                        totalRow("Subtotal", "S/ \(String(format: "%.2f", venta.subtotal))", .npPrimary)
                        Divider()
                        totalRow("IGV (18%)", "S/ \(String(format: "%.2f", venta.igv))", .npWarning)
                        Divider()
                        totalRow("TOTAL", "S/ \(String(format: "%.2f", venta.total))", .npSecondary)
                    }
                    .padding(16)
                }

                // Método de pago
                MPCard {
                    HStack(spacing: 12) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.npSecondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Método de pago")
                                .font(.system(size: 12))
                                .foregroundColor(.npSlate)
                            Text(venta.metodoPago ?? "Efectivo")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.npPrimary)
                        }
                        Spacer()
                    }
                    .padding(16)
                }
            }
            .padding(16)
        }
        .background(Color.npBg.ignoresSafeArea())
        .navigationTitle(venta.codigoVenta ?? "Detalle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { sharePDF() } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    private func sharePDF() {
        guard let data = PDFGenerator.generateSaleReceipt(venta: venta) else { return }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(venta.codigoVenta ?? "venta").pdf")
        try? data.write(to: tempURL)
        let av = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(av, animated: true)
        }
    }

    private func totalRow(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(title)
                .font(title == "TOTAL" ? .system(size: 15, weight: .bold) : .system(size: 13))
                .foregroundColor(.npSlate)
            Spacer()
            Text(value)
                .font(title == "TOTAL" ? .system(size: 20, weight: .bold) : .system(size: 14, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

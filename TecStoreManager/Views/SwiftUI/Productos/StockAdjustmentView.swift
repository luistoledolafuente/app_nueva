import SwiftUI

struct StockAdjustmentView: View {
    @Environment(\.dismiss) var dismiss
    let producto: Producto
    let onSave: (Int) -> Void

    @State private var nuevaCantidad: Int
    @State private var motivo = "Compra"

    private let motivos = ["Compra", "Ajuste", "Devolución", "Merma"]

    init(producto: Producto, onSave: @escaping (Int) -> Void) {
        self.producto = producto
        self.onSave = onSave
        _nuevaCantidad = State(initialValue: Int(producto.stock))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.npBg.ignoresSafeArea()
                VStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text(producto.nombre ?? "-")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.npPrimary)
                        Text("Código: \(producto.codigo ?? "-")")
                            .font(.system(size: 13))
                            .foregroundColor(.npSlate)
                    }

                    HStack(spacing: 20) {
                        Button {
                            if nuevaCantidad > 0 { nuevaCantidad -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.npDanger)
                        }

                        VStack(spacing: 2) {
                            Text("\(nuevaCantidad)")
                                .font(.system(size: 42, weight: .bold, design: .monospaced))
                                .foregroundColor(.npPrimary)
                            Text("unidades")
                                .font(.system(size: 12))
                                .foregroundColor(.npSlate)
                        }
                        .frame(minWidth: 100)

                        Button {
                            nuevaCantidad += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.npSecondary)
                        }
                    }
                    .padding(20)
                    .background(Color.npCard)
                    .cornerRadius(16)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("MOTIVO DEL AJUSTE".uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.npSlate)
                            .padding(.leading, 4)

                        HStack(spacing: 8) {
                            ForEach(motivos, id: \.self) { m in
                                NPFilterChip(label: m, selected: motivo == m, color: .npSecondary) {
                                    motivo = m
                                }
                            }
                        }
                    }

                    if nuevaCantidad != Int(producto.stock) {
                        let diff = nuevaCantidad - Int(producto.stock)
                        HStack {
                            Image(systemName: diff > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .foregroundColor(diff > 0 ? .npSecondary : .npDanger)
                            Text(diff > 0
                                 ? "Aumentará en \(diff) unidades"
                                 : "Disminuirá en \(-diff) unidades")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(diff > 0 ? .npSecondary : .npDanger)
                        }
                        .padding(12)
                        .background((diff > 0 ? Color.npSecondary : Color.npDanger).opacity(0.08))
                        .cornerRadius(10)
                    }

                    Spacer()

                    Button {
                        onSave(nuevaCantidad)
                        dismiss()
                    } label: {
                        Text("Guardar Ajuste")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.npSecondary)
                            .cornerRadius(14)
                    }
                    .disabled(nuevaCantidad < 0)
                }
                .padding(24)
            }
            .navigationTitle("Ajustar Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.npDanger)
                }
            }
        }
    }
}

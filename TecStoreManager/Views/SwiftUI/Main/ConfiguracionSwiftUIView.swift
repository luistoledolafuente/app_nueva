import SwiftUI

struct ConfiguracionSwiftUIView: View {
    @State private var darkMode    = false
    @State private var stockAlerts = true
    @State private var reminders   = false

    var body: some View {
        ZStack {
            Color.tsBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    appHeader
                    aparienciaCard
                    notifCard
                    fiscalCard
                    versionCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Configuración")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - App Header
    private var appHeader: some View {
        TSCard {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(ModuleGradient.productos.gradient)
                        .frame(width: 64, height: 64)
                    Image(systemName: "cart.fill.badge.plus")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: Color.tsIndigo.opacity(0.4), radius: 10, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text("TecStore Manager")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.tsText)
                    Text("Versión 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.tsSlate)
                    Text("Gestión inteligente")
                        .font(.caption)
                        .foregroundColor(.tsSlate)
                }
                Spacer()
            }
            .padding(16)
        }
    }

    // MARK: - Apariencia
    private var aparienciaCard: some View {
        TSCard {
            VStack(spacing: 0) {
                sectionHeader(icon: "paintbrush.fill", title: "Apariencia", color: .tsIndigo)
                Divider().padding(.horizontal, 16)
                ConfigToggleRow(
                    icon: "moon.fill",
                    label: "Modo oscuro",
                    subtitle: "Interfaz oscura",
                    isOn: $darkMode,
                    color: .tsPurple
                )
            }
        }
    }

    // MARK: - Notificaciones
    private var notifCard: some View {
        TSCard {
            VStack(spacing: 0) {
                sectionHeader(icon: "bell.fill", title: "Notificaciones", color: .tsAmber)
                Divider().padding(.horizontal, 16)
                ConfigToggleRow(
                    icon: "exclamationmark.triangle.fill",
                    label: "Alertas de stock bajo",
                    subtitle: "Cuando stock ≤ 5 unidades",
                    isOn: $stockAlerts,
                    color: .tsRed
                )
                Divider().padding(.horizontal, 16)
                ConfigToggleRow(
                    icon: "calendar.badge.clock",
                    label: "Recordatorios",
                    subtitle: "Notificaciones diarias",
                    isOn: $reminders,
                    color: .tsBlue
                )
            }
        }
    }

    // MARK: - Fiscal
    private var fiscalCard: some View {
        TSCard {
            VStack(spacing: 0) {
                sectionHeader(icon: "doc.text.fill", title: "Fiscal", color: .tsEmerald)
                Divider().padding(.horizontal, 16)
                ConfigInfoRow(icon: "percent",       label: "Tasa IGV",  value: "18%",     color: .tsAmber)
                Divider().padding(.horizontal, 16)
                ConfigInfoRow(icon: "dollarsign",    label: "Moneda",    value: "S/. (PEN)", color: .tsEmerald)
            }
        }
    }

    // MARK: - Version
    private var versionCard: some View {
        TSCard {
            VStack(spacing: 0) {
                sectionHeader(icon: "info.circle.fill", title: "Acerca de", color: .tsSlate)
                Divider().padding(.horizontal, 16)
                ConfigInfoRow(icon: "hammer.fill",   label: "Tecnología",   value: "SwiftUI + CoreData", color: .tsBlue)
                Divider().padding(.horizontal, 16)
                ConfigInfoRow(icon: "cpu",            label: "Arquitectura", value: "MVVM + Repository",  color: .tsPurple)
                Divider().padding(.horizontal, 16)
                ConfigInfoRow(icon: "tag.fill",       label: "Versión",      value: "1.0.0",              color: .tsSlate)
            }
        }
    }

    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 15, weight: .semibold))
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.tsSlate)
                .textCase(.uppercase)
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Toggle Row
private struct ConfigToggleRow: View {
    let icon:     String
    let label:    String
    let subtitle: String
    @Binding var isOn: Bool
    let color:    Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.tsText)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.tsSlate)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Info Row
private struct ConfigInfoRow: View {
    let icon:  String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.tsText)
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.tsSlate)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

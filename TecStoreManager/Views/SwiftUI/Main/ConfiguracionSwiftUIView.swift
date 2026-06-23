import SwiftUI

struct ConfiguracionSwiftUIView: View {
    @AppStorage("darkMode")   private var darkMode    = false
    @AppStorage("stockAlerts") private var stockAlerts = true {
        didSet { if stockAlerts { NotificationManager.shared.scheduleDailyStockCheck() } }
    }
    @AppStorage("reminders")  private var reminders   = false {
        didSet {
            if reminders {
                NotificationManager.shared.scheduleDailyStockCheck()
            } else {
                NotificationManager.shared.cancelAll()
            }
        }
    }

    var body: some View {
        ZStack {
            Color.npBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    profileHeader
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

    private var profileHeader: some View {
        NPTopCard(color: .npSlate2) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(NPGradient.configuracion.gradient)
                        .frame(width: 60, height: 60)
                    Image(systemName: "gearshape.2.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: NPGradient.configuracion.start.opacity(0.3), radius: 8, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Configuración")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.npPrimary)
                    Text("Personaliza tu experiencia")
                        .font(.subheadline)
                        .foregroundColor(.npSlate)
                }
                Spacer()
            }
            .padding(16)
        }
    }

    private var aparienciaCard: some View {
        NPTopCard(color: .npSecondary) {
            VStack(spacing: 0) {
                sectionHeader(icon: "paintbrush.fill", title: "Apariencia", color: .npSecondary)
                Divider().padding(.horizontal, 16)
                ConfigToggleRow(
                    icon: "moon.fill",
                    label: "Modo oscuro",
                    subtitle: "Interfaz oscura",
                    isOn: $darkMode,
                    color: .npViolet
                )
            }
        }
    }

    private var notifCard: some View {
        NPTopCard(color: .npAmber) {
            VStack(spacing: 0) {
                sectionHeader(icon: "bell.fill", title: "Notificaciones", color: .npAmber)
                Divider().padding(.horizontal, 16)
                ConfigToggleRow(
                    icon: "exclamationmark.triangle.fill",
                    label: "Alertas de stock bajo",
                    subtitle: "Cuando stock ≤ 5 unidades",
                    isOn: $stockAlerts,
                    color: .npDanger
                )
                Divider().padding(.horizontal, 16)
                ConfigToggleRow(
                    icon: "calendar.badge.clock",
                    label: "Recordatorios",
                    subtitle: "Notificaciones diarias",
                    isOn: $reminders,
                    color: .npSecondary
                )
            }
        }
    }

    private var fiscalCard: some View {
        NPTopCard(color: .npEmerald) {
            VStack(spacing: 0) {
                sectionHeader(icon: "doc.text.fill", title: "Fiscal", color: .npEmerald)
                Divider().padding(.horizontal, 16)
                ConfigInfoRow(icon: "percent",       label: "Tasa IGV",  value: "18%",     color: .npAmber)
                Divider().padding(.horizontal, 16)
                ConfigInfoRow(icon: "dollarsign",    label: "Moneda",    value: "S/. (PEN)", color: .npEmerald)
            }
        }
    }

    private var versionCard: some View {
        NPTopCard(color: .npSlate2) {
            VStack(spacing: 0) {
                sectionHeader(icon: "info.circle.fill", title: "Acerca de", color: .npSlate2)
                Divider().padding(.horizontal, 16)
                ConfigInfoRow(icon: "hammer.fill",   label: "Tecnología",   value: "SwiftUI + CoreData", color: .npSecondary)
                Divider().padding(.horizontal, 16)
                ConfigInfoRow(icon: "cpu",            label: "Arquitectura", value: "MVVM + Repository",  color: .npViolet)
                Divider().padding(.horizontal, 16)
                ConfigInfoRow(icon: "tag.fill",       label: "Versión",      value: "1.0.0",              color: .npSlate2)
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
                .foregroundColor(.npSlate)
                .textCase(.uppercase)
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct ConfigToggleRow: View {
    let icon:     String
    let label:    String
    let subtitle: String
    @Binding var isOn: Bool
    let color:    Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.npPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.npSlate)
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

private struct ConfigInfoRow: View {
    let icon:  String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.npPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.npSlate)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

import SwiftUI

struct AcercaDeSwiftUIView: View {
    @State private var appeared = false

    private let techStack: [(String, String, Color)] = [
        ("swift",         "SwiftUI",     .npOrange),
        ("cylinder.split.1x2.fill", "Core Data", .npSecondary),
        ("cpu",           "MVVM",        .npViolet),
        ("building.columns.fill", "Repository Pattern", .npRose),
        ("location.fill", "MapKit",      .npDanger),
        ("lock.shield.fill", "CryptoKit", .npEmerald),
        ("flame.fill",    "Firebase",    .npAmber),
    ]

    var body: some View {
        ZStack {
            Color.npBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    heroSection
                    infoCard
                    techStackCard
                    teamCard
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Acerca de")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(NPGradient.acercaDe.gradient)
                    .frame(width: 100, height: 100)
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 80, height: 80)
                Image(systemName: "cart.fill.badge.plus")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: Color.npCyan.opacity(0.4), radius: 16, x: 0, y: 6)
            .scaleEffect(appeared ? 1 : 0.6)
            .opacity(appeared ? 1 : 0)

            Text("TecStore Manager")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.npPrimary)
                .opacity(appeared ? 1 : 0)

            NPBadge(text: "Versión 1.0.0", color: .npCyan)
                .opacity(appeared ? 1 : 0)
        }
    }

    private var infoCard: some View {
        NPTopCard(color: .npCyan) {
            VStack(spacing: 0) {
                cardHeader(icon: "info.circle.fill", title: "Información", color: .npCyan)
                Divider().padding(.horizontal, 16)
                infoRow(icon: "scope",          label: "Propósito",   value: "Gestión de tienda tecnológica")
                Divider().padding(.horizontal, 16)
                infoRow(icon: "iphone",          label: "Plataforma",  value: "iOS 16+")
                Divider().padding(.horizontal, 16)
                infoRow(icon: "globe.americas",  label: "Idioma",      value: "Español")
            }
        }
    }

    private var techStackCard: some View {
        NPTopCard(color: .npSecondary) {
            VStack(alignment: .leading, spacing: 14) {
                cardHeader(icon: "hammer.fill", title: "Stack tecnológico", color: .npSecondary)
                Divider().padding(.horizontal, 16)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(techStack.indices, id: \.self) { i in
                        let (icon, name, color) = techStack[i]
                        HStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(color.opacity(0.12))
                                    .frame(width: 28, height: 28)
                                Image(systemName: icon)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(color)
                            }
                            Text(name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.npPrimary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.npBg)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .scaleEffect(appeared ? 1 : 0.85)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.3).delay(Double(i) * 0.06), value: appeared)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    private var teamCard: some View {
        NPTopCard(color: .npIndigo) {
            VStack(spacing: 0) {
                cardHeader(icon: "person.2.fill", title: "Equipo", color: .npIndigo)
                Divider().padding(.horizontal, 16)

                HStack(spacing: 14) {
                    NPAvatar(name: "Juan Leon", gradient: .clientes)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Juan Leon")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.npPrimary)
                        Text("Instructor")
                            .font(.caption)
                            .foregroundColor(.npSlate)
                        NPBadge(text: "Desarrollo iOS", color: .npIndigo)
                    }
                    Spacer()
                }
                .padding(16)
            }
        }
    }

    private func cardHeader(icon: String, title: String, color: Color) -> some View {
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

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.npCyan)
                .font(.system(size: 14))
                .frame(width: 20)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.npSlate)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.npPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

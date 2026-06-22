import SwiftUI

struct AcercaDeSwiftUIView: View {
    @State private var logoRotation: Double = 0
    @State private var appeared = false

    private let techStack: [(String, String, Color)] = [
        ("swift",         "SwiftUI",     .tsOrange),
        ("cylinder.split.1x2.fill", "Core Data", .tsBlue),
        ("cpu",           "MVVM",        .tsPurple),
        ("building.columns.fill", "Repository Pattern", .tsTeal),
        ("location.fill", "MapKit",      .tsRed),
        ("lock.shield.fill", "CryptoKit", .tsEmerald),
    ]

    var body: some View {
        ZStack {
            Color.tsBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
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
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.1)) {
                appeared = true
            }
        }
    }

    // MARK: - Hero
    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(ModuleGradient.acercaDe.gradient)
                    .frame(width: 110, height: 110)
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 88, height: 88)
                Image(systemName: "cart.fill.badge.plus")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(logoRotation))
            }
            .shadow(color: Color.tsTeal.opacity(0.5), radius: 20, x: 0, y: 8)
            .scaleEffect(appeared ? 1 : 0.5)
            .opacity(appeared ? 1 : 0)
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    logoRotation += 360
                }
            }

            Text("TecStore Manager")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.tsText)
                .opacity(appeared ? 1 : 0)

            TSBadge(text: "Versión 1.0.0", color: .tsIndigo)
        }
    }

    // MARK: - Info Card
    private var infoCard: some View {
        TSCard {
            VStack(spacing: 0) {
                cardHeader(icon: "info.circle.fill", title: "Información", color: .tsTeal)
                Divider().padding(.horizontal, 16)
                infoRow(icon: "scope",          label: "Propósito",   value: "Gestión de tienda tecnológica")
                Divider().padding(.horizontal, 16)
                infoRow(icon: "iphone",          label: "Plataforma",  value: "iOS 16+")
                Divider().padding(.horizontal, 16)
                infoRow(icon: "globe.americas",  label: "Idioma",      value: "Español")
            }
        }
    }

    // MARK: - Tech Stack Card
    private var techStackCard: some View {
        TSCard {
            VStack(alignment: .leading, spacing: 14) {
                cardHeader(icon: "hammer.fill", title: "Stack tecnológico", color: .tsBlue)
                Divider().padding(.horizontal, 16)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(techStack.indices, id: \.self) { i in
                        let (icon, name, color) = techStack[i]
                        HStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(color.opacity(0.12))
                                    .frame(width: 30, height: 30)
                                Image(systemName: icon)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(color)
                            }
                            Text(name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.tsText)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color(hex: "#F8FAFC"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .scaleEffect(appeared ? 1 : 0.8)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(i) * 0.07), value: appeared)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Team Card
    private var teamCard: some View {
        TSCard {
            VStack(spacing: 0) {
                cardHeader(icon: "person.2.fill", title: "Equipo", color: .tsIndigo)
                Divider().padding(.horizontal, 16)

                HStack(spacing: 14) {
                    TSAvatar(name: "Juan Leon", gradient: .clientes)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Juan Leon")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.tsText)
                        Text("Instructor")
                            .font(.caption)
                            .foregroundColor(.tsSlate)
                        TSBadge(text: "Desarrollo iOS", color: .tsIndigo)
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
                .foregroundColor(.tsSlate)
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
                .foregroundColor(.tsTeal)
                .font(.system(size: 14))
                .frame(width: 20)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.tsSlate)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.tsText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

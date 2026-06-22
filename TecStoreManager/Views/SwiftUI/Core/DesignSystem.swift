import SwiftUI

// MARK: - Extended Colors
extension Color {
    static let tsIndigo    = Color(hex: "#4F46E5")
    static let tsPurple    = Color(hex: "#7C3AED")
    static let tsCyan      = Color(hex: "#06B6D4")
    static let tsBlue      = Color(hex: "#3B82F6")
    static let tsEmerald   = Color(hex: "#10B981")
    static let tsTeal      = Color(hex: "#14B8A6")
    static let tsRed       = Color(hex: "#EF4444")
    static let tsOrange    = Color(hex: "#F97316")
    static let tsAmber     = Color(hex: "#F59E0B")
    static let tsPink      = Color(hex: "#EC4899")
    static let tsSlate     = Color(hex: "#64748B")
    static let tsBg        = Color(hex: "#F1F5F9")
    static let tsCard      = Color.white
    static let tsText      = Color(hex: "#1E2024")
}

// MARK: - Module Gradients
struct ModuleGradient {
    let start: Color
    let end:   Color

    static let productos     = ModuleGradient(start: .tsIndigo,  end: .tsPurple)
    static let clientes      = ModuleGradient(start: .tsCyan,    end: .tsBlue)
    static let ventas        = ModuleGradient(start: .tsEmerald, end: .tsTeal)
    static let busquedas     = ModuleGradient(start: .tsPurple,  end: .tsPink)
    static let mapa          = ModuleGradient(start: .tsRed,     end: .tsOrange)
    static let reportes      = ModuleGradient(start: .tsAmber,   end: .tsOrange)
    static let configuracion = ModuleGradient(start: .tsSlate,   end: Color(hex: "#475569"))
    static let acercaDe      = ModuleGradient(start: .tsTeal,    end: .tsCyan)

    var gradient: LinearGradient {
        LinearGradient(colors: [start, end], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Card Container
struct TSCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .background(Color.tsCard)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon:     String
    let value:    String
    let label:    String
    let gradient: ModuleGradient

    var body: some View {
        TSCard {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(gradient.gradient)
                        .frame(width: 46, height: 46)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.tsText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.tsSlate)
                    .lineLimit(1)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Primary Button
struct TSPrimaryButtonStyle: ButtonStyle {
    var gradient: ModuleGradient = ModuleGradient(start: .tsIndigo, end: .tsPurple)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(gradient.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Destructive Button
struct TSDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.tsRed)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Input Field
struct TSField: View {
    let icon:        String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure:    Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.tsSlate)
                .frame(width: 22)
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 15))
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .font(.system(size: 15))
            }
        }
        .padding(14)
        .background(Color(hex: "#F8FAFC"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.tsIndigo.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Badge
struct TSBadge: View {
    let text:  String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }
}

// MARK: - Avatar (iniciales)
struct TSAvatar: View {
    let name:     String
    let gradient: ModuleGradient

    private var initials: String {
        let parts = name.split(separator: " ")
        let chars = parts.prefix(2).compactMap { $0.first.map { String($0) } }
        return chars.joined().uppercased()
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(gradient.gradient)
                .frame(width: 46, height: 46)
            Text(initials.isEmpty ? "?" : initials)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Empty State
struct TSEmptyState: View {
    let icon:     String
    let title:    String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(Color.tsSlate.opacity(0.35))
            Text(title)
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(.tsText)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.tsSlate)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Error Banner
struct TSErrorBanner: View {
    let message: String

    var body: some View {
        if !message.isEmpty {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.tsRed)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.tsRed)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.tsRed.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon:  String
    let label: String
    let value: String
    var iconColor: Color = .tsIndigo

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.tsSlate)
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.tsText)
            }
            Spacer()
        }
    }
}

// MARK: - Currency formatter
func formatCurrency(_ value: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle             = .decimal
    f.minimumFractionDigits   = 2
    f.maximumFractionDigits   = 2
    return "S/ " + (f.string(from: NSNumber(value: value)) ?? "0.00")
}

func formatDate(_ date: Date?) -> String {
    guard let date else { return "-" }
    let f = DateFormatter()
    f.dateFormat = "dd/MM/yyyy"
    return f.string(from: date)
}

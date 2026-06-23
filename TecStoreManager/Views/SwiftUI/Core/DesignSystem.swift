import SwiftUI
import UIKit

// MARK: - Paleta Market
extension Color {
    static let npPrimary   = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "#F8FAFC") : UIColor(hex: "#0F172A")
    })
    static let npAccent    = Color(hex: "#F59E0B")
    static let npSecondary = Color(hex: "#059669")
    static let npSuccess   = Color(hex: "#10B981")
    static let npDanger    = Color(hex: "#EF4444")
    static let npWarning   = Color(hex: "#F59E0B")
    static let npBg        = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "#0F172A") : UIColor(hex: "#F1F5F9")
    })
    static let npCard      = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "#1E293B") : UIColor(hex: "#FFFFFF")
    })
    static let npBorder    = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "#334155") : UIColor(hex: "#E2E8F0")
    })
    static let npText      = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "#F8FAFC") : UIColor(hex: "#0F172A")
    })
    static let npMuted     = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "#94A3B8") : UIColor(hex: "#64748B")
    })
    static let npSlate     = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "#94A3B8") : UIColor(hex: "#64748B")
    })

    static let npRose      = Color(hex: "#F43F5E")
    static let npIndigo    = Color(hex: "#6366F1")
    static let npEmerald   = Color(hex: "#059669")
    static let npViolet    = Color(hex: "#8B5CF6")
    static let npOrange    = Color(hex: "#F97316")
    static let npAmber     = Color(hex: "#F59E0B")
    static let npCyan      = Color(hex: "#06B6D4")
    static let npSlate2    = Color(hex: "#64748B")
}

// MARK: - Gradientes
struct NPGradient {
    let start: Color
    let end:   Color

    static let productos     = NPGradient(start: Color(hex: "#F43F5E"), end: Color(hex: "#BE123C"))
    static let clientes      = NPGradient(start: Color(hex: "#6366F1"), end: Color(hex: "#4338CA"))
    static let ventas        = NPGradient(start: Color(hex: "#059669"), end: Color(hex: "#047857"))
    static let busquedas     = NPGradient(start: Color(hex: "#8B5CF6"), end: Color(hex: "#6D28D9"))
    static let mapa          = NPGradient(start: Color(hex: "#F97316"), end: Color(hex: "#C2410C"))
    static let reportes      = NPGradient(start: Color(hex: "#F59E0B"), end: Color(hex: "#B45309"))
    static let configuracion = NPGradient(start: Color(hex: "#64748B"), end: Color(hex: "#475569"))
    static let acercaDe      = NPGradient(start: Color(hex: "#06B6D4"), end: Color(hex: "#0891B2"))
    static let dashboard     = NPGradient(start: Color(hex: "#059669"), end: Color(hex: "#047857"))

    var gradient: LinearGradient {
        LinearGradient(gradient: Gradient(colors: [start, end]), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Tarjeta moderna
struct MPCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(Color.npCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct MPCardAccent<Content: View>: View {
    let color: Color
    let content: Content

    init(color: Color, @ViewBuilder content: () -> Content) {
        self.color = color
        self.content = content()
    }

    var body: some View {
        content
            .background(Color.npCard)
            .overlay(
                Rectangle()
                    .fill(color)
                    .frame(height: 4),
                alignment: .top
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - NPTopCard (deprecated, mantener para compatibilidad)
struct NPTopCard<Content: View>: View {
    let color: Color
    let content: Content

    init(color: Color, @ViewBuilder content: () -> Content) {
        self.color = color
        self.content = content()
    }

    var body: some View {
        MPCardAccent(color: color) { content }
    }
}

// MARK: - Botón primario
struct MPButtonStyle: ButtonStyle {
    var color: Color = .npSecondary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(configuration.isPressed ? color.opacity(0.85) : color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct NPWPButtonStyle: ButtonStyle {
    var color: Color = .npAccent

    func makeBody(configuration: Configuration) -> some View {
        MPButtonStyle(color: color).makeBody(configuration: configuration)
    }
}

// MARK: - Botón outline
struct MPOutlineButtonStyle: ButtonStyle {
    var color: Color = .npSecondary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(configuration.isPressed ? color.opacity(0.06) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

struct NPOutlineButtonStyle: ButtonStyle {
    var color: Color = .npSecondary

    func makeBody(configuration: Configuration) -> some View {
        MPOutlineButtonStyle(color: color).makeBody(configuration: configuration)
    }
}

// MARK: - Campo de texto moderno
struct MPField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var accentColor: Color = .npSecondary
    var textColor: Color = .npPrimary
    var placeholderColor: Color = .npMuted
    var bgColor: Color = .npBg
    var borderColor: Color = .npBorder

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(placeholderColor)
                .frame(width: 18)
            if isSecure {
                SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(placeholderColor))
                    .font(.system(size: 15))
                    .foregroundColor(textColor)
            } else {
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(placeholderColor))
                    .keyboardType(keyboardType)
                    .font(.system(size: 15))
                    .foregroundColor(textColor)
            }
        }
        .padding(14)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(!text.isEmpty ? accentColor : borderColor, lineWidth: 1)
        )
    }
}

struct NPField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var accentColor: Color = .npAccent
    var textColor: Color = .npPrimary
    var placeholderColor: Color = .npMuted
    var bgColor: Color = .npBg
    var borderColor: Color = .npBorder

    var body: some View {
        MPField(
            icon: icon,
            placeholder: placeholder,
            text: $text,
            keyboardType: keyboardType,
            isSecure: isSecure,
            accentColor: accentColor,
            textColor: textColor,
            placeholderColor: placeholderColor,
            bgColor: bgColor,
            borderColor: borderColor
        )
    }
}

// MARK: - Badge
struct MPBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }
}

struct NPBadge: View {
    let text: String
    let color: Color

    var body: some View {
        MPBadge(text: text, color: color)
    }
}

// MARK: - Avatar
struct MPAvatar: View {
    let name: String
    let gradient: NPGradient

    private var initials: String {
        let parts = name.split(separator: " ")
        let chars = parts.prefix(2).compactMap { $0.first.map { String($0) } }
        return chars.joined().uppercased()
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(gradient.gradient)
                .frame(width: 40, height: 40)
            Text(initials.isEmpty ? "?" : initials)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
        .shadow(color: gradient.start.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

struct NPAvatar: View {
    let name: String
    let gradient: NPGradient

    var body: some View {
        MPAvatar(name: name, gradient: gradient)
    }
}

// MARK: - Empty State
struct MPEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.npMuted.opacity(0.08))
                    .frame(width: 72, height: 72)
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(Color.npMuted.opacity(0.4))
            }
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.npPrimary)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(.npMuted)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

struct NPEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        MPEmptyState(icon: icon, title: title, subtitle: subtitle)
    }
}

// MARK: - Error Banner
struct MPErrorBanner: View {
    let message: String

    var body: some View {
        if !message.isEmpty {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.npDanger)
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.npDanger)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.npDanger.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct NPErrorBanner: View {
    let message: String

    var body: some View {
        MPErrorBanner(message: message)
    }
}

// MARK: - Info Row
struct MPInfoRow: View {
    let icon: String
    let label: String
    let value: String
    var iconColor: Color = .npSecondary

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.npMuted)
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.npPrimary)
            }
            Spacer()
        }
    }
}

struct NPInfoRow: View {
    let icon: String
    let label: String
    let value: String
    var iconColor: Color = .npSecondary

    var body: some View {
        MPInfoRow(icon: icon, label: label, value: value, iconColor: iconColor)
    }
}

// MARK: - Filter Chip
struct MPFilterChip: View {
    let label: String
    let selected: Bool
    var color: Color = .npSecondary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(selected ? .white : color)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(selected ? color : Color.clear)
                .overlay(
                    Capsule()
                        .stroke(selected ? Color.clear : color, lineWidth: 1.2)
                )
                .clipShape(Capsule())
        }
    }
}

struct NPFilterChip: View {
    let label: String
    let selected: Bool
    var color: Color = .npSecondary
    let action: () -> Void

    var body: some View {
        MPFilterChip(label: label, selected: selected, color: color, action: action)
    }
}

// MARK: - Formateadores
func formatCurrency(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    return "S/ " + (formatter.string(from: NSNumber(value: value)) ?? "0.00")
}

func formatDate(_ date: Date?) -> String {
    guard let date = date else { return "-" }
    let formatter = DateFormatter()
    formatter.dateFormat = "dd/MM/yyyy"
    return formatter.string(from: date)
}

import UIKit
import SwiftUI

// MARK: - Colores
enum AppColors {
    
    // UIKit
    static let primary       = UIColor(hex: "#4F46E5")
    static let primaryDark   = UIColor(hex: "#3730A3")
    static let background    = UIColor(hex: "#F4F5FA")
    static let surface       = UIColor(hex: "#FFFFFF")
    static let surfaceCard   = UIColor(hex: "#FFFFFF")
    static let textPrimary   = UIColor(hex: "#1E2024")
    static let textSecondary = UIColor(hex: "#64748B")
    static let accent        = UIColor(hex: "#4F46E5")
    static let success       = UIColor(hex: "#10B981")
    static let danger        = UIColor(hex: "#EF4444")
    static let warning       = UIColor(hex: "#F59E0B")

    // SwiftUI
    static let swPrimary     = Color(hex: "#4F46E5")
    static let swBackground  = Color(hex: "#F4F5FA")
    static let swSurface     = Color(hex: "#FFFFFF")
    static let swSurfaceCard = Color(hex: "#FFFFFF")
    static let swAccent      = Color(hex: "#4F46E5")
    static let swTextSecond  = Color(hex: "#64748B")
    static let swSuccess     = Color(hex: "#10B981")
    static let swDanger      = Color(hex: "#EF4444")
    static let swWarning     = Color(hex: "#F59E0B")
}

// MARK: - Extension UIColor desde Hex
extension UIColor {
    convenience init(hex: String) {
        var hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        self.init(
            red:   CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8)  & 0xFF) / 255,
            blue:  CGFloat( rgb        & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Extension Color desde Hex
extension Color {
    init(hex: String) {
        self.init(UIColor(hex: hex))
    }
}

// MARK: - Constantes generales
enum AppConstants {
    static let igvRate:        Double  = 0.18
    static let appName:        String  = "TecStore Manager"
    static let cornerRadius:   CGFloat = 12
    static let paddingGeneral: CGFloat = 16
}

// MARK: - Helpers de diseño
extension UIView {
    @discardableResult
    func addCard(frame: CGRect) -> UIView {
        let card = UIView(frame: frame)
        card.backgroundColor    = AppColors.surface
        card.layer.cornerRadius = 16
        card.layer.borderWidth  = 0.5
        card.layer.borderColor  = AppColors.primary.withAlphaComponent(0.15).cgColor
        insertSubview(card, at: 0)
        return card
    }
}

extension UIViewController {
    @discardableResult
    func addCaption(above label: UILabel, text: String) -> UILabel {
        let caption = UILabel(frame: CGRect(x: label.frame.minX, y: label.frame.minY - 18, width: label.frame.width, height: 16))
        caption.text      = text
        caption.font      = .systemFont(ofSize: 12, weight: .medium)
        caption.textColor = AppColors.textSecondary
        view.addSubview(caption)
        return caption
    }
}

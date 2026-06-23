import UIKit
import SwiftUI

// MARK: - Colores
enum AppColors {
    
    // UIKit
    static let primary       = UIColor(hex: "#F43F5E")
    static let primaryDark   = UIColor(hex: "#BE123C")
    static let background    = UIColor(hex: "#FAFAF9")
    static let surface       = UIColor(hex: "#FFFFFF")
    static let surfaceCard   = UIColor(hex: "#FFFFFF")
    static let textPrimary   = UIColor(hex: "#292524")
    static let textSecondary = UIColor(hex: "#78716C")
    static let accent        = UIColor(hex: "#6366F1")
    static let success       = UIColor(hex: "#22C55E")
    static let danger        = UIColor(hex: "#EF4444")
    static let warning       = UIColor(hex: "#F59E0B")

    // SwiftUI
    static let swPrimary     = Color(hex: "#F43F5E")
    static let swBackground  = Color(hex: "#FAFAF9")
    static let swSurface     = Color(hex: "#FFFFFF")
    static let swSurfaceCard = Color(hex: "#FFFFFF")
    static let swAccent      = Color(hex: "#6366F1")
    static let swTextSecond  = Color(hex: "#78716C")
    static let swSuccess     = Color(hex: "#22C55E")
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
    static let cornerRadius:   CGFloat = 8
    static let paddingGeneral: CGFloat = 16
}

// MARK: - Helpers de diseño
extension UIView {
    @discardableResult
    func addCard(frame: CGRect) -> UIView {
        let card = UIView(frame: frame)
        card.backgroundColor    = AppColors.surface
        card.layer.cornerRadius = 8
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

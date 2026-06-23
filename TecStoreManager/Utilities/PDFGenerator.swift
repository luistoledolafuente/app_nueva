import UIKit

class PDFGenerator {
    static func generateSaleReceipt(venta: Venta) -> Data? {
        let pageWidth: CGFloat = 280
        let pageHeight: CGFloat = 600
        let margin: CGFloat = 20

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let data = renderer.pdfData { ctx in
            ctx.beginPage()

            let context = ctx.cgContext
            let rect = ctx.pdfContextBounds

            // Title
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor(hex: "#059669")
            ]
            let title = "TecStore Manager"
            title.draw(at: CGPoint(x: margin, y: 20), withAttributes: titleAttrs)

            let subtitle = "Comprobante de Venta\n\n"
            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor(hex: "#78716C")
            ]
            subtitle.draw(at: CGPoint(x: margin, y: 44), withAttributes: subAttrs)

            // Separator
            context.setLineWidth(1)
            context.setStrokeColor(UIColor.systemGray5.cgColor)
            context.move(to: CGPoint(x: margin, y: 66))
            context.addLine(to: CGPoint(x: pageWidth - margin, y: 66))
            context.strokePath()

            var y: CGFloat = 78

            // Sale code and date
            let code = "Código: \(venta.codigoVenta ?? "-")"
            let smallAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor(hex: "#292524")
            ]
            code.draw(at: CGPoint(x: margin, y: y), withAttributes: smallAttrs)
            y += 16

            let df = DateFormatter()
            df.dateFormat = "dd/MM/yyyy HH:mm"
            let dateStr = "Fecha: \(df.string(from: venta.fechaVenta ?? Date()))"
            dateStr.draw(at: CGPoint(x: margin, y: y), withAttributes: smallAttrs)
            y += 16

            let methodStr = "Pago: \(venta.metodoPago ?? "Efectivo")"
            methodStr.draw(at: CGPoint(x: margin, y: y), withAttributes: smallAttrs)
            y += 16

            let clientStr = "Cliente: \(venta.cliente?.nombres ?? "") \(venta.cliente?.apellidos ?? "")"
            clientStr.draw(at: CGPoint(x: margin, y: y), withAttributes: smallAttrs)
            y += 20

            // Products header
            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 11),
                .foregroundColor: UIColor(hex: "#292524")
            ]
            let descHeader = "Producto"
            descHeader.draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttrs)

            let qtyHeader = "Cant"
            qtyHeader.draw(at: CGPoint(x: 160, y: y), withAttributes: headerAttrs)

            let priceHeader = "P.U."
            priceHeader.draw(at: CGPoint(x: 190, y: y), withAttributes: headerAttrs)

            let subHeader = "Subtotal"
            subHeader.draw(at: CGPoint(x: 220, y: y), withAttributes: headerAttrs)
            y += 16

            // Separator
            context.move(to: CGPoint(x: margin, y: y))
            context.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            context.strokePath()
            y += 6

            // Products
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor(hex: "#292524")
            ]
            let bodyRight: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor(hex: "#292524")
            ]

            guard let detalles = venta.detalles as? Set<DetalleVenta> else { return }
            let sorted = detalles.sorted { ($0.producto?.nombre ?? "") < ($1.producto?.nombre ?? "") }

            for detalle in sorted {
                let name = detalle.producto?.nombre ?? "-"
                let truncated = name.count > 22 ? String(name.prefix(22)) + "..." : name
                truncated.draw(at: CGPoint(x: margin, y: y), withAttributes: bodyAttrs)

                "\(detalle.cantidad)".draw(at: CGPoint(x: 160, y: y), withAttributes: bodyRight)
                "S/ \(String(format: "%.2f", detalle.precioUnitario))".draw(at: CGPoint(x: 178, y: y), withAttributes: bodyRight)
                "S/ \(String(format: "%.2f", detalle.subtotal))".draw(at: CGPoint(x: 218, y: y), withAttributes: bodyRight)
                y += 14
            }

            y += 8

            // Separator
            context.move(to: CGPoint(x: margin, y: y))
            context.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            context.strokePath()
            y += 10

            // Totals
            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor(hex: "#78716C")
            ]
            let valueAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: UIColor(hex: "#292524")
            ]

            "Subtotal".draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttrs)
            "S/ \(String(format: "%.2f", venta.subtotal))".draw(at: CGPoint(x: 210, y: y), withAttributes: valueAttrs)
            y += 16

            "IGV (18%)".draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttrs)
            "S/ \(String(format: "%.2f", venta.igv))".draw(at: CGPoint(x: 210, y: y), withAttributes: valueAttrs)
            y += 16

            let totalLabelAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor(hex: "#059669")
            ]
            let totalValueAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor(hex: "#059669")
            ]
            "TOTAL".draw(at: CGPoint(x: margin, y: y), withAttributes: totalLabelAttrs)
            "S/ \(String(format: "%.2f", venta.total))".draw(at: CGPoint(x: 200, y: y), withAttributes: totalValueAttrs)
            y += 30

            // Footer
            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9),
                .foregroundColor: UIColor(hex: "#78716C")
            ]
            "Gracias por su compra".draw(at: CGPoint(x: margin, y: y), withAttributes: footerAttrs)
        }

        return data
    }

    static func sharePDF(venta: Venta, from viewController: UIViewController) {
        guard let data = generateSaleReceipt(venta: venta) else { return }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(venta.codigoVenta ?? "venta").pdf")
        try? data.write(to: tempURL)
        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        viewController.present(activityVC, animated: true)
    }
}

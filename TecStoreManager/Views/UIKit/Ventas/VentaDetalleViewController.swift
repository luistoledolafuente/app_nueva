import UIKit

class VentaDetalleViewController: UIViewController {

    private let venta: Venta
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    init(venta: Venta) {
        self.venta = venta
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        title = venta.codigoVenta ?? "Detalle de Venta"
        navigationController?.navigationBar.tintColor = AppColors.accent

        let shareBtn = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(compartirPDF))
        shareBtn.tintColor = AppColors.accent
        navigationItem.rightBarButtonItem = shareBtn

        setupUI()
    }

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])

        addClienteCard()
        addProductosSection()
        addResumenCard()
        addMetodoPagoCard()
    }

    private func makeCard() -> UIView {
        let card = UIView()
        card.backgroundColor = AppColors.surface
        card.layer.cornerRadius = 14
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.04
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 6
        return card
    }

    private func addClienteCard() {
        let card = makeCard()
        stackView.addArrangedSubview(card)

        let nombreCliente = "\(venta.cliente?.nombres ?? "") \(venta.cliente?.apellidos ?? "")"
        let dniCliente = venta.cliente?.dni ?? "-"

        let icon = UIImageView(image: UIImage(systemName: "person.circle.fill"))
        icon.tintColor = AppColors.accent
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(icon)

        let nombreLbl = UILabel()
        nombreLbl.text = nombreCliente
        nombreLbl.font = .systemFont(ofSize: 16, weight: .semibold)
        nombreLbl.textColor = AppColors.textPrimary
        nombreLbl.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(nombreLbl)

        let dniLbl = UILabel()
        dniLbl.text = "DNI: \(dniCliente)"
        dniLbl.font = .systemFont(ofSize: 13)
        dniLbl.textColor = AppColors.textSecondary
        dniLbl.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(dniLbl)

        let fechaLbl = UILabel()
        let df = DateFormatter()
        df.dateFormat = "dd/MM/yyyy HH:mm"
        fechaLbl.text = df.string(from: venta.fechaVenta ?? Date())
        fechaLbl.font = .systemFont(ofSize: 12)
        fechaLbl.textColor = AppColors.textSecondary
        fechaLbl.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(fechaLbl)

        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),

            icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 28),
            icon.heightAnchor.constraint(equalToConstant: 28),

            nombreLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            nombreLbl.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            nombreLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            dniLbl.topAnchor.constraint(equalTo: nombreLbl.bottomAnchor, constant: 4),
            dniLbl.leadingAnchor.constraint(equalTo: nombreLbl.leadingAnchor),
            dniLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            fechaLbl.topAnchor.constraint(equalTo: dniLbl.bottomAnchor, constant: 2),
            fechaLbl.leadingAnchor.constraint(equalTo: nombreLbl.leadingAnchor),
            fechaLbl.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }

    private func addProductosSection() {
        let headerLbl = UILabel()
        headerLbl.text = "PRODUCTOS".uppercased()
        headerLbl.font = .systemFont(ofSize: 12, weight: .bold)
        headerLbl.textColor = AppColors.textSecondary
        stackView.addArrangedSubview(headerLbl)

        guard let detalles = venta.detalles as? Set<DetalleVenta> else { return }
        let sorted = detalles.sorted { ($0.producto?.nombre ?? "") < ($1.producto?.nombre ?? "") }

        for detalle in sorted {
            let card = makeCard()
            stackView.addArrangedSubview(card)

            let nombreLbl = UILabel()
            nombreLbl.text = detalle.producto?.nombre ?? "-"
            nombreLbl.font = .systemFont(ofSize: 14, weight: .semibold)
            nombreLbl.textColor = AppColors.textPrimary
            nombreLbl.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(nombreLbl)

            let detalleLbl = UILabel()
            let descuento = detalle.descuento
            if descuento > 0 {
                detalleLbl.text = "S/ \(String(format: "%.2f", detalle.precioUnitario)) c/u × \(detalle.cantidad)  (Desc. S/ \(String(format: "%.2f", descuento)))"
            } else {
                detalleLbl.text = "S/ \(String(format: "%.2f", detalle.precioUnitario)) c/u × \(detalle.cantidad)"
            }
            detalleLbl.font = .systemFont(ofSize: 12)
            detalleLbl.textColor = AppColors.textSecondary
            detalleLbl.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(detalleLbl)

            let subtotalLbl = UILabel()
            subtotalLbl.text = "S/ \(String(format: "%.2f", detalle.subtotal))"
            subtotalLbl.font = .systemFont(ofSize: 15, weight: .bold)
            subtotalLbl.textColor = AppColors.accent
            subtotalLbl.textAlignment = .right
            subtotalLbl.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(subtotalLbl)

            NSLayoutConstraint.activate([
                card.heightAnchor.constraint(greaterThanOrEqualToConstant: 64),

                nombreLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
                nombreLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                nombreLbl.trailingAnchor.constraint(equalTo: subtotalLbl.leadingAnchor, constant: -8),

                detalleLbl.topAnchor.constraint(equalTo: nombreLbl.bottomAnchor, constant: 2),
                detalleLbl.leadingAnchor.constraint(equalTo: nombreLbl.leadingAnchor),
                detalleLbl.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),

                subtotalLbl.centerYAnchor.constraint(equalTo: card.centerYAnchor),
                subtotalLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                subtotalLbl.widthAnchor.constraint(greaterThanOrEqualToConstant: 90)
            ])
        }
    }

    private func addResumenCard() {
        let card = makeCard()
        stackView.addArrangedSubview(card)

        let rows: [(String, String, UIColor)] = [
            ("Subtotal", "S/ \(String(format: "%.2f", venta.subtotal))", AppColors.textPrimary),
            ("IGV (18%)", "S/ \(String(format: "%.2f", venta.igv))", AppColors.warning),
            ("Total", "S/ \(String(format: "%.2f", venta.total))", AppColors.greenEm)
        ]

        var topAnchorConstraint = card.topAnchor
        let inset: CGFloat = 16
        let spacing: CGFloat = 12

        for (title, value, color) in rows {
            let t = UILabel()
            t.text = title
            t.font = title == "Total" ? .systemFont(ofSize: 15, weight: .bold) : .systemFont(ofSize: 13)
            t.textColor = AppColors.textSecondary
            t.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(t)

            let v = UILabel()
            v.text = value
            v.font = title == "Total" ? .systemFont(ofSize: 20, weight: .bold) : .systemFont(ofSize: 14, weight: .semibold)
            v.textColor = color
            v.textAlignment = .right
            v.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(v)

            NSLayoutConstraint.activate([
                t.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: inset),
                t.centerYAnchor.constraint(equalTo: v.centerYAnchor),
                t.topAnchor.constraint(equalTo: topAnchorConstraint, constant: title == "Subtotal" ? inset : spacing),

                v.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -inset),
                v.widthAnchor.constraint(greaterThanOrEqualToConstant: 100)
            ])

            topAnchorConstraint = v.bottomAnchor

            if title != "Total" {
                let sep = UIView()
                sep.backgroundColor = UIColor.systemGray6
                sep.translatesAutoresizingMaskIntoConstraints = false
                card.addSubview(sep)
                NSLayoutConstraint.activate([
                    sep.topAnchor.constraint(equalTo: v.bottomAnchor, constant: 8),
                    sep.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: inset),
                    sep.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -inset),
                    sep.heightAnchor.constraint(equalToConstant: 1)
                ])
            } else {
                topAnchorConstraint.constraint(equalTo: card.bottomAnchor, constant: -inset).isActive = true
            }
        }
    }

    @objc private func compartirPDF() {
        PDFGenerator.sharePDF(venta: venta, from: self)
    }

    private func addMetodoPagoCard() {
        let card = makeCard()
        stackView.addArrangedSubview(card)

        let icon = UIImageView(image: UIImage(systemName: "creditcard.fill"))
        icon.tintColor = AppColors.greenEm
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(icon)

        let lbl = UILabel()
        lbl.text = "Método de pago"
        lbl.font = .systemFont(ofSize: 13)
        lbl.textColor = AppColors.textSecondary
        lbl.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(lbl)

        let valueLbl = UILabel()
        valueLbl.text = venta.metodoPago ?? "Efectivo"
        valueLbl.font = .systemFont(ofSize: 16, weight: .semibold)
        valueLbl.textColor = AppColors.textPrimary
        valueLbl.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(valueLbl)

        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),

            icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),

            lbl.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            lbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),

            valueLbl.leadingAnchor.constraint(equalTo: lbl.leadingAnchor),
            valueLbl.topAnchor.constraint(equalTo: lbl.bottomAnchor, constant: 2),
            valueLbl.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
    }
}

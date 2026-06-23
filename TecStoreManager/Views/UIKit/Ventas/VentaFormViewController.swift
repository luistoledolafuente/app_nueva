import UIKit

struct ItemCarrito {
    let producto: Producto
    var cantidad: Int
    let precioUnitario: Double
    var subtotal: Double { Double(cantidad) * precioUnitario }
}

class VentaFormViewController: UIViewController {

    var viewModel = VentaViewModel()

    private let clienteRepo  = ClienteRepository()
    private let productoRepo = ProductoRepository()

    private var clientes:  [Cliente]  = []
    private var productos: [Producto] = []
    private var clienteSeleccionado: Cliente?
    private var itemsCarrito: [ItemCarrito] = []

    private let tableView = UITableView(frame: .zero, style: .grouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        title = "Nueva Venta"
        navigationController?.navigationBar.tintColor = AppColors.accent

        setupTableView()
        cargarDatos()
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ClienteCell")
        tableView.register(ProductoCatalogoCell.self, forCellReuseIdentifier: ProductoCatalogoCell.id)
        tableView.register(CarritoItemCell.self, forCellReuseIdentifier: CarritoItemCell.id)
        tableView.register(TotalFooter.self, forHeaderFooterViewReuseIdentifier: TotalFooter.id)

        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset.bottom = 20
        tableView.showsVerticalScrollIndicator = false

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func cargarDatos() {
        clientes  = clienteRepo.obtenerTodos()
        productos = productoRepo.obtenerTodos().filter { $0.stock > 0 && $0.estado }
    }

    private func agregarProductoAlCarrito(producto: Producto) {
        guard producto.stock > 0 else { return }
        if let idx = itemsCarrito.firstIndex(where: { $0.producto.idProducto == producto.idProducto }) {
            guard itemsCarrito[idx].cantidad < producto.stock else {
                showError("Stock máximo alcanzado para \(producto.nombre ?? "")")
                return
            }
            itemsCarrito[idx].cantidad += 1
        } else {
            itemsCarrito.append(ItemCarrito(producto: producto, cantidad: 1, precioUnitario: producto.precio))
        }
        tableView.reloadData()
        if itemsCarrito.count == 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                let sec = self.productos.isEmpty ? 1 : 2
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: sec), at: .top, animated: true)
            }
        }
    }

    private func showError(_ msg: String) {
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func registrarVenta() {
        guard let cliente = clienteSeleccionado else {
            showError("Selecciona un cliente")
            return
        }
        guard !itemsCarrito.isEmpty else {
            showError("Agrega al menos un producto al carrito")
            return
        }
        let prods = itemsCarrito.map { ($0.producto, $0.cantidad) }
        if viewModel.crear(cliente: cliente, productos: prods) {
            navigationController?.popViewController(animated: true)
        } else {
            showError(viewModel.errorMessage)
        }
    }
}

// MARK: - UITableView
extension VentaFormViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return productos.isEmpty ? 2 : 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return productos.count
        case 2: return max(itemsCarrito.count, 1)
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ClienteCell", for: indexPath)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }

            let card = UIView()
            card.backgroundColor = AppColors.surface
            card.layer.cornerRadius = 14
            card.layer.borderWidth = 1
            card.layer.borderColor = clienteSeleccionado != nil
                ? AppColors.success.withAlphaComponent(0.3).cgColor
                : UIColor.systemGray5.cgColor
            card.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(card)

            let icon = UIImageView()
            icon.image = UIImage(systemName: "person.circle.fill")
            icon.tintColor = AppColors.accent
            icon.contentMode = .scaleAspectFit
            icon.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(icon)

            let label = UILabel()
            label.text = clienteSeleccionado != nil
                ? "\(clienteSeleccionado!.nombres ?? "") \(clienteSeleccionado!.apellidos ?? "")"
                : "Seleccionar cliente"
            label.font = .systemFont(ofSize: 15, weight: .semibold)
            label.textColor = clienteSeleccionado != nil ? AppColors.textPrimary : AppColors.textSecondary
            label.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(label)

            let chevron = UILabel()
            chevron.text = "›"
            chevron.font = .systemFont(ofSize: 22, weight: .bold)
            chevron.textColor = AppColors.textSecondary
            chevron.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(chevron)

            NSLayoutConstraint.activate([
                card.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 4),
                card.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                card.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                card.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -4),
                card.heightAnchor.constraint(equalToConstant: 54),

                icon.centerYAnchor.constraint(equalTo: card.centerYAnchor),
                icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
                icon.widthAnchor.constraint(equalToConstant: 24),
                icon.heightAnchor.constraint(equalToConstant: 24),

                label.centerYAnchor.constraint(equalTo: card.centerYAnchor),
                label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 10),
                label.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),

                chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor),
                chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14)
            ])
            return cell

        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: ProductoCatalogoCell.id, for: indexPath) as! ProductoCatalogoCell
            let p = productos[indexPath.row]
            let enCarrito = itemsCarrito.first { $0.producto.idProducto == p.idProducto }
            cell.configure(with: p, cantidadEnCarrito: enCarrito?.cantidad ?? 0)
            cell.onAgregar = { [weak self] in
                self?.agregarProductoAlCarrito(producto: p)
            }
            return cell

        case 2:
            if itemsCarrito.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ClienteCell", for: indexPath)
                cell.backgroundColor = .clear
                cell.selectionStyle = .none
                cell.contentView.subviews.forEach { $0.removeFromSuperview() }

                let hintView = UIView()
                hintView.backgroundColor = AppColors.tintGreen
                hintView.layer.cornerRadius = 14
                hintView.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.addSubview(hintView)

                let lbl = UILabel()
                lbl.text = "Toca \"AGREGAR\" arriba para añadir productos"
                lbl.font = .systemFont(ofSize: 13)
                lbl.textColor = AppColors.greenEm
                lbl.numberOfLines = 0
                lbl.textAlignment = .center
                lbl.translatesAutoresizingMaskIntoConstraints = false
                hintView.addSubview(lbl)

                NSLayoutConstraint.activate([
                    hintView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 4),
                    hintView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                    hintView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                    hintView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -4),
                    hintView.heightAnchor.constraint(equalToConstant: 50),

                    lbl.centerXAnchor.constraint(equalTo: hintView.centerXAnchor),
                    lbl.centerYAnchor.constraint(equalTo: hintView.centerYAnchor)
                ])
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: CarritoItemCell.id, for: indexPath) as! CarritoItemCell
            let item = itemsCarrito[indexPath.row]
            cell.configure(with: item)
            cell.onMas = { [weak self] in
                guard let self = self else { return }
                if item.cantidad < item.producto.stock {
                    self.itemsCarrito[indexPath.row].cantidad += 1
                    self.tableView.reloadData()
                }
            }
            cell.onMenos = { [weak self] in
                guard let self = self else { return }
                if item.cantidad > 1 {
                    self.itemsCarrito[indexPath.row].cantidad -= 1
                } else {
                    self.itemsCarrito.remove(at: indexPath.row)
                }
                self.tableView.reloadData()
            }
            cell.onEliminar = { [weak self] in
                self?.itemsCarrito.remove(at: indexPath.row)
                self?.tableView.reloadData()
            }
            return cell

        default: return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            let alert = UIAlertController(title: "Seleccionar Cliente", message: nil, preferredStyle: .actionSheet)
            for c in clientes {
                alert.addAction(UIAlertAction(title: "\(c.nombres ?? "") \(c.apellidos ?? "")", style: .default) { _ in
                    self.clienteSeleccionado = c
                    self.tableView.reloadSections(IndexSet(integer: 0), with: .none)
                })
            }
            alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
            present(alert, animated: true)
        }
    }

    // MARK: - Section Headers (estilo moderno con barra decorativa)
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let h = UIView()
        h.backgroundColor = .clear

        let bar = UIView()
        bar.backgroundColor = section == 2 && !itemsCarrito.isEmpty ? AppColors.success : AppColors.accent
        bar.layer.cornerRadius = 2
        bar.translatesAutoresizingMaskIntoConstraints = false
        h.addSubview(bar)

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        h.addSubview(label)

        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: h.leadingAnchor, constant: 20),
            bar.centerYAnchor.constraint(equalTo: h.centerYAnchor),
            bar.widthAnchor.constraint(equalToConstant: 3),
            bar.heightAnchor.constraint(equalToConstant: 16),

            label.leadingAnchor.constraint(equalTo: bar.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: h.trailingAnchor, constant: -20),
            label.bottomAnchor.constraint(equalTo: h.bottomAnchor, constant: -6)
        ])

        switch section {
        case 0:
            label.text = "CLIENTE"
            label.font = .systemFont(ofSize: 12, weight: .bold)
            label.textColor = AppColors.textSecondary
        case 1:
            label.text = "PRODUCTOS"
            label.font = .systemFont(ofSize: 12, weight: .bold)
            label.textColor = AppColors.textSecondary
        case 2:
            let count = itemsCarrito.reduce(0) { $0 + $1.cantidad }
            label.text = count > 0 ? "CARRITO (\(count) items)" : "CARRITO"
            label.font = .systemFont(ofSize: 12, weight: .bold)
            label.textColor = count > 0 ? AppColors.success : AppColors.textSecondary
            bar.backgroundColor = count > 0 ? AppColors.success : AppColors.textSecondary

            if count > 0 {
                let total = itemsCarrito.reduce(0.0) { $0 + $1.subtotal }
                let totalLbl = UILabel()
                totalLbl.text = "S/ \(String(format: "%.2f", total))"
                totalLbl.font = .systemFont(ofSize: 13, weight: .bold)
                totalLbl.textColor = AppColors.success
                totalLbl.textAlignment = .right
                totalLbl.translatesAutoresizingMaskIntoConstraints = false
                h.addSubview(totalLbl)
                NSLayoutConstraint.activate([
                    totalLbl.trailingAnchor.constraint(equalTo: h.trailingAnchor, constant: -20),
                    totalLbl.bottomAnchor.constraint(equalTo: h.bottomAnchor, constant: -6)
                ])
            }
        default: break
        }
        return h
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32
    }

    // MARK: - Footer
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == (productos.isEmpty ? 1 : 2), !itemsCarrito.isEmpty else { return nil }

        let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: TotalFooter.id) as! TotalFooter
        let subtotal = itemsCarrito.reduce(0.0) { $0 + $1.subtotal }
        let igv = subtotal * AppConstants.igvRate
        let total = subtotal + igv
        footer.configure(subtotal: subtotal, igv: igv, total: total, itemCount: itemsCarrito.reduce(0) { $0 + $1.cantidad })

        footer.onRegistrar = { [weak self] in self?.registrarVenta() }
        footer.onCancelar = { [weak self] in self?.navigationController?.popViewController(animated: true) }
        return footer
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard section == (productos.isEmpty ? 1 : 2), !itemsCarrito.isEmpty else { return 0 }
        return 290
    }
}

// MARK: - ProductoCatalogoCell (diseño moderno)
class ProductoCatalogoCell: UITableViewCell {
    static let id = "ProductoCatalogoCell"

    private let cardView = UIView()
    private let nombreLabel = UILabel()
    private let precioLabel = UILabel()
    private let stockBadge = UIView()
    private let stockLabel = UILabel()
    private let agregarButton = UIButton()
    private let badgeCarrito = UILabel()

    var onAgregar: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        cardView.backgroundColor = AppColors.surface
        cardView.layer.cornerRadius = 14
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.04
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 6
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        nombreLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nombreLabel.textColor = AppColors.textPrimary
        nombreLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(nombreLabel)

        precioLabel.font = .systemFont(ofSize: 15, weight: .bold)
        precioLabel.textColor = AppColors.accent
        precioLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(precioLabel)

        stockBadge.layer.cornerRadius = 8
        stockBadge.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(stockBadge)

        stockLabel.font = .systemFont(ofSize: 10, weight: .medium)
        stockLabel.translatesAutoresizingMaskIntoConstraints = false
        stockBadge.addSubview(stockLabel)

        agregarButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        agregarButton.setTitleColor(.white, for: .normal)
        agregarButton.layer.cornerRadius = 16
        agregarButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        agregarButton.translatesAutoresizingMaskIntoConstraints = false
        agregarButton.addTarget(self, action: #selector(agregarTapped), for: .touchUpInside)
        cardView.addSubview(agregarButton)

        badgeCarrito.backgroundColor = AppColors.primary
        badgeCarrito.textColor = .white
        badgeCarrito.font = .systemFont(ofSize: 10, weight: .bold)
        badgeCarrito.textAlignment = .center
        badgeCarrito.layer.cornerRadius = 10
        badgeCarrito.clipsToBounds = true
        badgeCarrito.isHidden = true
        badgeCarrito.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(badgeCarrito)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),

            nombreLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            nombreLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            nombreLabel.trailingAnchor.constraint(equalTo: agregarButton.leadingAnchor, constant: -8),

            precioLabel.topAnchor.constraint(equalTo: nombreLabel.bottomAnchor, constant: 2),
            precioLabel.leadingAnchor.constraint(equalTo: nombreLabel.leadingAnchor),

            stockBadge.topAnchor.constraint(equalTo: precioLabel.bottomAnchor, constant: 4),
            stockBadge.leadingAnchor.constraint(equalTo: nombreLabel.leadingAnchor),
            stockBadge.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -9),

            stockLabel.topAnchor.constraint(equalTo: stockBadge.topAnchor, constant: 2),
            stockLabel.leadingAnchor.constraint(equalTo: stockBadge.leadingAnchor, constant: 6),
            stockLabel.trailingAnchor.constraint(equalTo: stockBadge.trailingAnchor, constant: -6),
            stockLabel.bottomAnchor.constraint(equalTo: stockBadge.bottomAnchor, constant: -2),

            agregarButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            agregarButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            agregarButton.heightAnchor.constraint(equalToConstant: 32),

            badgeCarrito.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 6),
            badgeCarrito.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -6),
            badgeCarrito.widthAnchor.constraint(equalToConstant: 20),
            badgeCarrito.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    func configure(with producto: Producto, cantidadEnCarrito: Int) {
        nombreLabel.text = producto.nombre ?? ""
        precioLabel.text = "S/ \(String(format: "%.2f", producto.precio))"

        if producto.stock == 0 {
            stockBadge.backgroundColor = AppColors.tintRed
            stockLabel.text = "Agotado"
            stockLabel.textColor = AppColors.danger
            agregarButton.setTitle("AGOTADO", for: .normal)
            agregarButton.backgroundColor = AppColors.muted
            agregarButton.isEnabled = false
            badgeCarrito.isHidden = true
        } else if producto.stock <= 5 {
            stockBadge.backgroundColor = AppColors.tintYellow
            stockLabel.text = "Stock: \(producto.stock)"
            stockLabel.textColor = AppColors.warning
            agregarButton.isEnabled = true
            if cantidadEnCarrito > 0 {
                badgeCarrito.isHidden = false
                badgeCarrito.text = "\(cantidadEnCarrito)"
                agregarButton.setTitle("+1", for: .normal)
                agregarButton.backgroundColor = AppColors.greenEm
            } else {
                badgeCarrito.isHidden = true
                agregarButton.setTitle("AGREGAR", for: .normal)
                agregarButton.backgroundColor = AppColors.primary
            }
        } else {
            stockBadge.backgroundColor = AppColors.tintGreen
            stockLabel.text = "Stock: \(producto.stock)"
            stockLabel.textColor = AppColors.greenEm
            agregarButton.isEnabled = true
            if cantidadEnCarrito > 0 {
                badgeCarrito.isHidden = false
                badgeCarrito.text = "\(cantidadEnCarrito)"
                agregarButton.setTitle("+1", for: .normal)
                agregarButton.backgroundColor = AppColors.greenEm
            } else {
                badgeCarrito.isHidden = true
                agregarButton.setTitle("AGREGAR", for: .normal)
                agregarButton.backgroundColor = AppColors.primary
            }
        }
    }

    @objc private func agregarTapped() { onAgregar?() }
}

// MARK: - CarritoItemCell (diseño limpio)
class CarritoItemCell: UITableViewCell {
    static let id = "CarritoItemCell"

    private let cardView = UIView()
    private let nombreLabel = UILabel()
    private let precioLabel = UILabel()
    private let stepperView = UIView()
    private let menosButton = UIButton()
    private let cantidadLabel = UILabel()
    private let masButton = UIButton()
    private let subtotalLabel = UILabel()

    var onMas: (() -> Void)?
    var onMenos: (() -> Void)?
    var onEliminar: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        cardView.backgroundColor = AppColors.surface
        cardView.layer.cornerRadius = 14
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = AppColors.greenEm.withAlphaComponent(0.15).cgColor
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        nombreLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        nombreLabel.textColor = AppColors.textPrimary
        nombreLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(nombreLabel)

        precioLabel.font = .systemFont(ofSize: 11)
        precioLabel.textColor = AppColors.textSecondary
        precioLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(precioLabel)

        // Stepper
        stepperView.backgroundColor = AppColors.tintWarm
        stepperView.layer.cornerRadius = 16
        stepperView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(stepperView)

        menosButton.setTitle("−", for: .normal)
        menosButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        menosButton.setTitleColor(AppColors.danger, for: .normal)
        menosButton.translatesAutoresizingMaskIntoConstraints = false
        menosButton.addTarget(self, action: #selector(menosTapped), for: .touchUpInside)
        stepperView.addSubview(menosButton)

        cantidadLabel.font = .systemFont(ofSize: 15, weight: .bold)
        cantidadLabel.textColor = AppColors.textPrimary
        cantidadLabel.textAlignment = .center
        cantidadLabel.translatesAutoresizingMaskIntoConstraints = false
        stepperView.addSubview(cantidadLabel)

        masButton.setTitle("+", for: .normal)
        masButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        masButton.setTitleColor(AppColors.greenEm, for: .normal)
        masButton.translatesAutoresizingMaskIntoConstraints = false
        masButton.addTarget(self, action: #selector(masTapped), for: .touchUpInside)
        stepperView.addSubview(masButton)

        subtotalLabel.font = .systemFont(ofSize: 15, weight: .bold)
        subtotalLabel.textColor = AppColors.accent
        subtotalLabel.textAlignment = .right
        subtotalLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(subtotalLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            nombreLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            nombreLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            nombreLabel.trailingAnchor.constraint(equalTo: stepperView.leadingAnchor, constant: -8),

            precioLabel.topAnchor.constraint(equalTo: nombreLabel.bottomAnchor, constant: 1),
            precioLabel.leadingAnchor.constraint(equalTo: nombreLabel.leadingAnchor),

            stepperView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            stepperView.trailingAnchor.constraint(equalTo: subtotalLabel.leadingAnchor, constant: -8),
            stepperView.widthAnchor.constraint(equalToConstant: 100),
            stepperView.heightAnchor.constraint(equalToConstant: 32),

            menosButton.leadingAnchor.constraint(equalTo: stepperView.leadingAnchor),
            menosButton.centerYAnchor.constraint(equalTo: stepperView.centerYAnchor),
            menosButton.widthAnchor.constraint(equalToConstant: 32),
            menosButton.heightAnchor.constraint(equalToConstant: 32),

            cantidadLabel.centerXAnchor.constraint(equalTo: stepperView.centerXAnchor),
            cantidadLabel.centerYAnchor.constraint(equalTo: stepperView.centerYAnchor),

            masButton.trailingAnchor.constraint(equalTo: stepperView.trailingAnchor),
            masButton.centerYAnchor.constraint(equalTo: stepperView.centerYAnchor),
            masButton.widthAnchor.constraint(equalToConstant: 32),
            masButton.heightAnchor.constraint(equalToConstant: 32),

            subtotalLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            subtotalLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            subtotalLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
    }

    func configure(with item: ItemCarrito) {
        nombreLabel.text = item.producto.nombre ?? ""
        precioLabel.text = "S/ \(String(format: "%.2f", item.precioUnitario)) c/u"
        cantidadLabel.text = "\(item.cantidad)"
        subtotalLabel.text = "S/ \(String(format: "%.2f", item.subtotal))"
    }

    @objc private func masTapped() { onMas?() }
    @objc private func menosTapped() { onMenos?() }
}

// MARK: - TotalFooter (diseño resumen profesional)
class TotalFooter: UITableViewHeaderFooterView {
    static let id = "TotalFooter"

    private let cardView = UIView()
    private let subtotalLabel = UILabel()
    private let igvLabel = UILabel()
    private let totalLabel = UILabel()
    private let registrarButton = UIButton()
    private let cancelarButton = UIButton()

    var onRegistrar: (() -> Void)?
    var onCancelar: (() -> Void)?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        cardView.backgroundColor = AppColors.surface
        cardView.layer.cornerRadius = 18
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowOffset = CGSize(width: 0, height: -4)
        cardView.layer.shadowRadius = 12
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        // Línea decorativa superior
        let topLine = UIView()
        topLine.backgroundColor = AppColors.primary
        topLine.layer.cornerRadius = 2
        topLine.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(topLine)

        let titleLbl = UILabel()
        titleLbl.text = "RESUMEN DE VENTA"
        titleLbl.font = .systemFont(ofSize: 11, weight: .bold)
        titleLbl.textColor = AppColors.textSecondary
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLbl)

        let rows = [
            ("Subtotal", subtotalLabel, AppColors.textPrimary, false),
            ("IGV (18%)", igvLabel, AppColors.warning, false),
            ("Total", totalLabel, AppColors.greenEm, true)
        ]

        var topAnchor = titleLbl.bottomAnchor
        let topConstant: CGFloat = 12

        for (title, label, color, big) in rows {
            let t = UILabel()
            t.text = title
            t.font = big ? .systemFont(ofSize: 15, weight: .bold) : .systemFont(ofSize: 13)
            t.textColor = AppColors.textSecondary
            t.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview(t)

            label.font = big ? .systemFont(ofSize: 20, weight: .bold) : .systemFont(ofSize: 14, weight: .semibold)
            label.textColor = color
            label.textAlignment = .right
            label.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview(label)

            t.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18).isActive = true
            t.centerYAnchor.constraint(equalTo: label.centerYAnchor).isActive = true
            label.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18).isActive = true
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
            t.topAnchor.constraint(equalTo: topAnchor, constant: topConstant).isActive = true

            // Línea separadora entre rows
            if !big {
                let sep = UIView()
                sep.backgroundColor = UIColor.systemGray6
                sep.translatesAutoresizingMaskIntoConstraints = false
                cardView.addSubview(sep)
                NSLayoutConstraint.activate([
                    sep.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
                    sep.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
                    sep.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),
                    sep.heightAnchor.constraint(equalToConstant: 1)
                ])
            }

            topAnchor = label.bottomAnchor
        }

        registrarButton.setTitle("  Registrar Venta  ", for: .normal)
        registrarButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        registrarButton.backgroundColor = AppColors.primary
        registrarButton.setTitleColor(.white, for: .normal)
        registrarButton.layer.cornerRadius = 16
        registrarButton.translatesAutoresizingMaskIntoConstraints = false
        registrarButton.addTarget(self, action: #selector(registrarTapped), for: .touchUpInside)
        cardView.addSubview(registrarButton)

        cancelarButton.setTitle("Cancelar venta", for: .normal)
        cancelarButton.setTitleColor(AppColors.danger, for: .normal)
        cancelarButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        cancelarButton.translatesAutoresizingMaskIntoConstraints = false
        cancelarButton.addTarget(self, action: #selector(cancelarTapped), for: .touchUpInside)
        cardView.addSubview(cancelarButton)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            topLine.topAnchor.constraint(equalTo: cardView.topAnchor),
            topLine.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            topLine.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),
            topLine.heightAnchor.constraint(equalToConstant: 3),

            titleLbl.topAnchor.constraint(equalTo: topLine.bottomAnchor, constant: 14),
            titleLbl.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),

            registrarButton.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            registrarButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            registrarButton.heightAnchor.constraint(equalToConstant: 50),

            cancelarButton.topAnchor.constraint(equalTo: registrarButton.bottomAnchor, constant: 8),
            cancelarButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            cancelarButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14)
        ])
    }

    func configure(subtotal: Double, igv: Double, total: Double, itemCount: Int) {
        subtotalLabel.text = "S/ \(String(format: "%.2f", subtotal))"
        igvLabel.text = "S/ \(String(format: "%.2f", igv))"
        totalLabel.text = "S/ \(String(format: "%.2f", total))"
        registrarButton.setTitle("  Registrar Venta (\(itemCount) items)  ", for: .normal)
    }

    @objc private func registrarTapped() { onRegistrar?() }
    @objc private func cancelarTapped() { onCancelar?() }
}

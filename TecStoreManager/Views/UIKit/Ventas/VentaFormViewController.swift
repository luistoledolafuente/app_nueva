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

    // MARK: - UI
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
        tableView.backgroundColor = AppColors.background
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

    private func agregarAlCarrito(producto: Producto, cantidad: Int) {
        if let idx = itemsCarrito.firstIndex(where: { $0.producto.idProducto == producto.idProducto }) {
            itemsCarrito[idx].cantidad += cantidad
        } else {
            itemsCarrito.append(ItemCarrito(producto: producto, cantidad: cantidad, precioUnitario: producto.precio))
        }
        tableView.reloadData()
        // Scroll al carrito
        if itemsCarrito.count == 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let carritoSec = self.productos.isEmpty ? 1 : 2
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: carritoSec), at: .top, animated: true)
            }
        }
    }

    // Al tocar "AGREGAR" en un producto, se añade 1 unidad al carrito
    // Si ya está en el carrito, se incrementa la cantidad en 1
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
        // Scroll al carrito después de agregar el primer producto
        if itemsCarrito.count == 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                let sec = self.productos.isEmpty ? 1 : 2
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: sec), at: .top, animated: true)
            }
        }
    }

    private func showError(_ msg: String) {
        // Mostrar error como toast simple
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
        return productos.isEmpty ? 2 : 3  // 0:Cliente, 1:Productos, 2:Carrito
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1                // Cliente
        case 1: return productos.count  // Catálogo
        case 2: return max(itemsCarrito.count, 1) // 1 fila de hint si está vacío
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

            let field = UITextField()
            field.placeholder = "Seleccionar cliente"
            field.text = clienteSeleccionado.map { "\($0.nombres ?? "") \($0.apellidos ?? "")" }
            field.backgroundColor = AppColors.surface
            field.textColor = AppColors.textPrimary
            field.layer.cornerRadius = 12
            field.layer.borderWidth = 0.5
            field.layer.borderColor = AppColors.primary.withAlphaComponent(0.3).cgColor
            field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
            field.leftViewMode = .always
            field.translatesAutoresizingMaskIntoConstraints = false
            field.isUserInteractionEnabled = false

            cell.contentView.addSubview(field)
            NSLayoutConstraint.activate([
                field.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 4),
                field.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                field.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                field.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -4),
                field.heightAnchor.constraint(equalToConstant: 44)
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
                let lbl = UILabel()
                lbl.text = "Toca \"AGREGAR\" en los productos de arriba para añadirlos al carrito 🛒"
                lbl.font = .systemFont(ofSize: 13)
                lbl.textColor = AppColors.textSecondary
                lbl.numberOfLines = 0
                lbl.textAlignment = .center
                lbl.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.addSubview(lbl)
                NSLayoutConstraint.activate([
                    lbl.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                    lbl.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                    lbl.leadingAnchor.constraint(greaterThanOrEqualTo: cell.contentView.leadingAnchor, constant: 40),
                    lbl.trailingAnchor.constraint(lessThanOrEqualTo: cell.contentView.trailingAnchor, constant: -40)
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
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                })
            }
            alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
            present(alert, animated: true)
        }
    }

    // MARK: - Headers
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let h = UIView()
        h.backgroundColor = .clear

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        h.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: h.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: h.trailingAnchor, constant: -20),
            label.bottomAnchor.constraint(equalTo: h.bottomAnchor, constant: -6)
        ])

        switch section {
        case 0:
            label.text = "CLIENTE"
            label.font = .systemFont(ofSize: 12, weight: .bold)
            label.textColor = AppColors.textSecondary
        case 1:
            label.text = "PRODUCTOS — toca AGREGAR para añadir al carrito"
            label.font = .systemFont(ofSize: 12, weight: .bold)
            label.textColor = AppColors.textSecondary
        case 2:
            let count = itemsCarrito.reduce(0) { $0 + $1.cantidad }
            label.text = "CARRITO (\(count) item\(count != 1 ? "s" : ""))"
            label.font = .systemFont(ofSize: 12, weight: .bold)
            label.textColor = AppColors.accent
            // Badge de total
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
        footer.configure(subtotal: subtotal, igv: igv, total: total)

        footer.onRegistrar = { [weak self] in self?.registrarVenta() }
        footer.onCancelar = { [weak self] in self?.navigationController?.popViewController(animated: true) }
        return footer
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard section == (productos.isEmpty ? 1 : 2), !itemsCarrito.isEmpty else { return 0 }
        return 260
    }
}

// MARK: - ProductoCatalogoCell
class ProductoCatalogoCell: UITableViewCell {
    static let id = "ProductoCatalogoCell"

    private let cardView = UIView()
    private let nombreLabel = UILabel()
    private let precioLabel = UILabel()
    private let stockLabel = UILabel()
    private let agregarButton = UIButton()
    private let badgeCarrito = UILabel()
    private let enCarritoLabel = UILabel()

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
        cardView.layer.cornerRadius = 12
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = AppColors.primary.withAlphaComponent(0.12).cgColor
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        nombreLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nombreLabel.textColor = AppColors.textPrimary
        nombreLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(nombreLabel)

        precioLabel.font = .systemFont(ofSize: 16, weight: .bold)
        precioLabel.textColor = AppColors.accent
        precioLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(precioLabel)

        stockLabel.font = .systemFont(ofSize: 11)
        stockLabel.textColor = AppColors.textSecondary
        stockLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(stockLabel)

        enCarritoLabel.font = .systemFont(ofSize: 11, weight: .medium)
        enCarritoLabel.textColor = AppColors.success
        enCarritoLabel.isHidden = true
        enCarritoLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(enCarritoLabel)

        // Botón AGREGAR grande y visible
        agregarButton.setTitle("  AGREGAR  ", for: .normal)
        agregarButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        agregarButton.backgroundColor = AppColors.primary
        agregarButton.setTitleColor(.white, for: .normal)
        agregarButton.layer.cornerRadius = 16
        agregarButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
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

            nombreLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            nombreLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            nombreLabel.trailingAnchor.constraint(equalTo: agregarButton.leadingAnchor, constant: -8),

            precioLabel.topAnchor.constraint(equalTo: nombreLabel.bottomAnchor, constant: 2),
            precioLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),

            stockLabel.topAnchor.constraint(equalTo: precioLabel.bottomAnchor, constant: 2),
            stockLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            stockLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),

            enCarritoLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            enCarritoLabel.trailingAnchor.constraint(equalTo: agregarButton.leadingAnchor, constant: -6),

            agregarButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            agregarButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            agregarButton.heightAnchor.constraint(equalToConstant: 34),

            badgeCarrito.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 6),
            badgeCarrito.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -6),
            badgeCarrito.widthAnchor.constraint(equalToConstant: 20),
            badgeCarrito.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    func configure(with producto: Producto, cantidadEnCarrito: Int) {
        nombreLabel.text = producto.nombre ?? ""
        precioLabel.text = "S/ \(String(format: "%.2f", producto.precio))"
        stockLabel.text = "Stock: \(producto.stock)"
        stockLabel.textColor = producto.stock <= 5 ? AppColors.danger : AppColors.textSecondary

        if cantidadEnCarrito > 0 {
            badgeCarrito.isHidden = false
            badgeCarrito.text = "\(cantidadEnCarrito)"
            enCarritoLabel.isHidden = false
            enCarritoLabel.text = "\(cantidadEnCarrito) en carrito"
            agregarButton.setTitle("+1", for: .normal)
            agregarButton.backgroundColor = AppColors.success
        } else {
            badgeCarrito.isHidden = true
            enCarritoLabel.isHidden = true
            agregarButton.setTitle("AGREGAR", for: .normal)
            agregarButton.backgroundColor = AppColors.primary
        }

        if producto.stock == 0 {
            agregarButton.setTitle("AGOTADO", for: .normal)
            agregarButton.backgroundColor = AppColors.textSecondary
            agregarButton.isEnabled = false
        } else {
            agregarButton.isEnabled = true
        }
    }

    @objc private func agregarTapped() { onAgregar?() }
}

// MARK: - CarritoItemCell
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
    private let eliminarButton = UIButton()

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
        cardView.layer.cornerRadius = 12
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = AppColors.accent.withAlphaComponent(0.2).cgColor
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

        // Stepper: - | cantidad | +
        stepperView.backgroundColor = AppColors.background
        stepperView.layer.cornerRadius = 14
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
        masButton.setTitleColor(AppColors.success, for: .normal)
        masButton.translatesAutoresizingMaskIntoConstraints = false
        masButton.addTarget(self, action: #selector(masTapped), for: .touchUpInside)
        stepperView.addSubview(masButton)

        subtotalLabel.font = .systemFont(ofSize: 15, weight: .bold)
        subtotalLabel.textColor = AppColors.accent
        subtotalLabel.textAlignment = .right
        subtotalLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(subtotalLabel)

        eliminarButton.setTitle("✕", for: .normal)
        eliminarButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        eliminarButton.setTitleColor(AppColors.danger.withAlphaComponent(0.6), for: .normal)
        eliminarButton.translatesAutoresizingMaskIntoConstraints = false
        eliminarButton.addTarget(self, action: #selector(eliminarTapped), for: .touchUpInside)
        cardView.addSubview(eliminarButton)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            nombreLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            nombreLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            nombreLabel.trailingAnchor.constraint(equalTo: eliminarButton.leadingAnchor, constant: -4),

            precioLabel.topAnchor.constraint(equalTo: nombreLabel.bottomAnchor, constant: 2),
            precioLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),

            stepperView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            stepperView.trailingAnchor.constraint(equalTo: subtotalLabel.leadingAnchor, constant: -8),
            stepperView.widthAnchor.constraint(equalToConstant: 100),
            stepperView.heightAnchor.constraint(equalToConstant: 28),

            menosButton.leadingAnchor.constraint(equalTo: stepperView.leadingAnchor),
            menosButton.centerYAnchor.constraint(equalTo: stepperView.centerYAnchor),
            menosButton.widthAnchor.constraint(equalToConstant: 32),
            menosButton.heightAnchor.constraint(equalToConstant: 28),

            cantidadLabel.centerXAnchor.constraint(equalTo: stepperView.centerXAnchor),
            cantidadLabel.centerYAnchor.constraint(equalTo: stepperView.centerYAnchor),

            masButton.trailingAnchor.constraint(equalTo: stepperView.trailingAnchor),
            masButton.centerYAnchor.constraint(equalTo: stepperView.centerYAnchor),
            masButton.widthAnchor.constraint(equalToConstant: 32),
            masButton.heightAnchor.constraint(equalToConstant: 28),

            subtotalLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            subtotalLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            subtotalLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),

            eliminarButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 4),
            eliminarButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -6),
            eliminarButton.widthAnchor.constraint(equalToConstant: 24),
            eliminarButton.heightAnchor.constraint(equalToConstant: 24)
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
    @objc private func eliminarTapped() { onEliminar?() }
}

// MARK: - TotalFooter
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
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowOffset = CGSize(width: 0, height: -2)
        cardView.layer.shadowRadius = 8
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        let titleLbl = UILabel()
        titleLbl.text = "RESUMEN"
        titleLbl.font = .systemFont(ofSize: 11, weight: .bold)
        titleLbl.textColor = AppColors.textSecondary
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLbl)

        let rows = [
            ("Subtotal", subtotalLabel, AppColors.textPrimary, false),
            ("IGV (18%)", igvLabel, AppColors.warning, false),
            ("Total", totalLabel, AppColors.success, true)
        ]

        var topAnchor = titleLbl.bottomAnchor
        let topConstant: CGFloat = 14

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

            t.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16).isActive = true
            t.centerYAnchor.constraint(equalTo: label.centerYAnchor).isActive = true
            label.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16).isActive = true
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true

            t.topAnchor.constraint(equalTo: topAnchor, constant: topConstant).isActive = true

            topAnchor = label.bottomAnchor
        }

        registrarButton.setTitle("Registrar Venta", for: .normal)
        registrarButton.backgroundColor = AppColors.primary
        registrarButton.setTitleColor(.white, for: .normal)
        registrarButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        registrarButton.layer.cornerRadius = 14
        registrarButton.translatesAutoresizingMaskIntoConstraints = false
        registrarButton.addTarget(self, action: #selector(registrarTapped), for: .touchUpInside)
        cardView.addSubview(registrarButton)

        cancelarButton.setTitle("Cancelar", for: .normal)
        cancelarButton.setTitleColor(AppColors.danger, for: .normal)
        cancelarButton.titleLabel?.font = .systemFont(ofSize: 14)
        cancelarButton.translatesAutoresizingMaskIntoConstraints = false
        cancelarButton.addTarget(self, action: #selector(cancelarTapped), for: .touchUpInside)
        cardView.addSubview(cancelarButton)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            titleLbl.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            titleLbl.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),

            registrarButton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            registrarButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            registrarButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            registrarButton.heightAnchor.constraint(equalToConstant: 50),

            cancelarButton.topAnchor.constraint(equalTo: registrarButton.bottomAnchor, constant: 8),
            cancelarButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            cancelarButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12)
        ])
    }

    func configure(subtotal: Double, igv: Double, total: Double) {
        subtotalLabel.text = "S/ \(String(format: "%.2f", subtotal))"
        igvLabel.text = "S/ \(String(format: "%.2f", igv))"
        totalLabel.text = "S/ \(String(format: "%.2f", total))"
    }

    @objc private func registrarTapped() { onRegistrar?() }
    @objc private func cancelarTapped() { onCancelar?() }
}

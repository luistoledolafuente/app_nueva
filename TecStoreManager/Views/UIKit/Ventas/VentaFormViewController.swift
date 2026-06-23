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

    // UI elements (programáticos)
    private let scrollView      = UIScrollView()
    private let contentView     = UIView()
    private let clienteField    = UITextField()
    private let tableView       = UITableView()
    private let agregarButton   = UIButton()
    private let subtotalLabel   = UILabel()
    private let igvLabel        = UILabel()
    private let totalLabel      = UILabel()
    private let errorLabel      = UILabel()
    private let registrarButton = UIButton()
    private let cancelarButton  = UIButton()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        cargarDatos()
    }

    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = AppColors.background
        title = "Nueva Venta"
        navigationController?.navigationBar.tintColor = AppColors.accent

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        var yOffset: CGFloat = 16

        // Cliente
        let clienteLabel = UILabel()
        clienteLabel.text = "Cliente"
        clienteLabel.font = .systemFont(ofSize: 13, weight: .medium)
        clienteLabel.textColor = AppColors.textSecondary
        clienteLabel.frame = CGRect(x: 24, y: yOffset, width: view.frame.width - 48, height: 18)
        contentView.addSubview(clienteLabel)
        yOffset += 24

        setupTextField(clienteField, placeholder: "Seleccionar cliente")
        clienteField.frame = CGRect(x: 24, y: yOffset, width: view.frame.width - 48, height: 44)
        clienteField.addTarget(self, action: #selector(clienteFieldTapped), for: .editingDidBegin)
        contentView.addSubview(clienteField)
        yOffset += 60

        // Productos header
        let prodLabel = UILabel()
        prodLabel.text = "Productos"
        prodLabel.font = .systemFont(ofSize: 13, weight: .medium)
        prodLabel.textColor = AppColors.textSecondary
        prodLabel.frame = CGRect(x: 24, y: yOffset, width: view.frame.width - 48, height: 18)
        contentView.addSubview(prodLabel)
        yOffset += 24

        // TableView para carrito
        tableView.frame = CGRect(x: 16, y: yOffset, width: view.frame.width - 32, height: min(CGFloat(itemsCarrito.count) * 84 + 8, 300))
        tableView.isScrollEnabled = false
        contentView.addSubview(tableView)
        yOffset += tableView.frame.height + 8

        // Botón agregar producto
        agregarButton.setTitle("+ Agregar Producto", for: .normal)
        agregarButton.backgroundColor    = AppColors.accent
        agregarButton.setTitleColor(.white, for: .normal)
        agregarButton.titleLabel?.font   = .systemFont(ofSize: 14, weight: .semibold)
        agregarButton.layer.cornerRadius = 10
        agregarButton.frame = CGRect(x: 24, y: yOffset, width: view.frame.width - 48, height: 40)
        agregarButton.addTarget(self, action: #selector(agregarProductoTapped), for: .touchUpInside)
        contentView.addSubview(agregarButton)
        yOffset += 56

        // Totales
        let card = UIView(frame: CGRect(x: 16, y: yOffset, width: view.frame.width - 32, height: 140))
        card.backgroundColor = AppColors.surface
        card.layer.cornerRadius = 10
        card.layer.borderWidth = 0.5
        card.layer.borderColor = AppColors.primary.withAlphaComponent(0.15).cgColor
        contentView.addSubview(card)

        var cy: CGFloat = 12
        let addTotalRow = { (title: String, label: UILabel, color: UIColor) in
            let titleLbl = UILabel()
            titleLbl.text = title
            titleLbl.font = .systemFont(ofSize: 14)
            titleLbl.textColor = AppColors.textSecondary
            titleLbl.frame = CGRect(x: 16, y: cy, width: 120, height: 22)
            card.addSubview(titleLbl)

            label.font      = .systemFont(ofSize: 15, weight: .semibold)
            label.textColor = color
            label.textAlignment = .right
            label.frame = CGRect(x: 140, y: cy, width: card.frame.width - 160, height: 22)
            card.addSubview(label)
            cy += 30
        }

        addTotalRow("Subtotal", subtotalLabel, AppColors.textPrimary)
        addTotalRow("IGV (18%)", igvLabel, AppColors.warning)
        addTotalRow("Total", totalLabel, AppColors.success)

        subtotalLabel.text = "S/ 0.00"
        igvLabel.text      = "S/ 0.00"
        totalLabel.text    = "S/ 0.00"
        totalLabel.font    = .systemFont(ofSize: 20, weight: .bold)

        yOffset += card.frame.height + 16

        // Error
        errorLabel.textColor     = AppColors.danger
        errorLabel.font          = .systemFont(ofSize: 13)
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorLabel.frame = CGRect(x: 24, y: yOffset, width: view.frame.width - 48, height: 20)
        contentView.addSubview(errorLabel)
        yOffset += 28

        // Registrar
        registrarButton.setTitle("Registrar Venta", for: .normal)
        registrarButton.backgroundColor    = AppColors.primary
        registrarButton.setTitleColor(.white, for: .normal)
        registrarButton.titleLabel?.font   = .systemFont(ofSize: 16, weight: .semibold)
        registrarButton.layer.cornerRadius = 12
        registrarButton.frame = CGRect(x: 24, y: yOffset, width: view.frame.width - 48, height: 50)
        registrarButton.addTarget(self, action: #selector(registrarTapped), for: .touchUpInside)
        contentView.addSubview(registrarButton)
        yOffset += 62

        // Cancelar
        cancelarButton.setTitle("Cancelar", for: .normal)
        cancelarButton.setTitleColor(AppColors.danger, for: .normal)
        cancelarButton.titleLabel?.font = .systemFont(ofSize: 15)
        cancelarButton.frame = CGRect(x: 24, y: yOffset, width: view.frame.width - 48, height: 40)
        cancelarButton.addTarget(self, action: #selector(cancelarTapped), for: .touchUpInside)
        contentView.addSubview(cancelarButton)
        yOffset += 60

        contentView.frame.size.height = yOffset
    }

    private func setupTextField(_ field: UITextField, placeholder: String) {
        field.placeholder           = placeholder
        field.backgroundColor       = AppColors.surface
        field.textColor             = AppColors.textPrimary
        field.layer.cornerRadius    = 12
        field.layer.borderWidth     = 0.5
        field.layer.borderColor     = AppColors.primary.withAlphaComponent(0.3).cgColor
        field.leftView              = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        field.leftViewMode          = .always
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: AppColors.textSecondary]
        )
    }

    private func setupTableView() {
        tableView.backgroundColor = AppColors.background
        tableView.separatorStyle  = .none
        tableView.delegate        = self
        tableView.dataSource      = self
        tableView.register(CarritoCell.self, forCellReuseIdentifier: CarritoCell.identifier)
        tableView.layer.cornerRadius = 10
    }

    private func cargarDatos() {
        clientes  = clienteRepo.obtenerTodos()
        productos = productoRepo.obtenerTodos()
    }

    // MARK: - Totales
    private func actualizarTotales() {
        let subtotal = itemsCarrito.reduce(0.0) { $0 + $1.subtotal }
        let igv      = subtotal * AppConstants.igvRate
        let total    = subtotal + igv

        subtotalLabel.text = "S/ \(String(format: "%.2f", subtotal))"
        igvLabel.text      = "S/ \(String(format: "%.2f", igv))"
        totalLabel.text    = "S/ \(String(format: "%.2f", total))"

        // Actualizar altura de la tabla
        let newHeight = min(CGFloat(itemsCarrito.count) * 84 + 8, 300)
        tableView.frame.size.height = newHeight

        // Re-posicionar elementos después de la tabla
        rePosicionarElementos()
        tableView.reloadData()
    }

    private func rePosicionarElementos() {
        var yOffset = tableView.frame.minY + tableView.frame.height + 8

        agregarButton.frame.origin.y = yOffset
        yOffset += 56

        // card de totales
        guard let card = subtotalLabel.superview else { return }
        card.frame.origin.y = yOffset
        yOffset += card.frame.height + 16

        errorLabel.frame.origin.y = yOffset
        yOffset += 28

        registrarButton.frame.origin.y = yOffset
        yOffset += 62

        cancelarButton.frame.origin.y = yOffset
        yOffset += 60

        contentView.frame.size.height = yOffset
        scrollView.contentSize.height = yOffset
    }

    // MARK: - Actions
    @objc private func clienteFieldTapped() {
        clienteField.resignFirstResponder()
        let alert = UIAlertController(title: "Seleccionar Cliente", message: nil, preferredStyle: .actionSheet)
        for cliente in clientes {
            alert.addAction(UIAlertAction(title: "\(cliente.nombres ?? "") \(cliente.apellidos ?? "")", style: .default) { _ in
                self.clienteSeleccionado = cliente
                self.clienteField.text   = "\(cliente.nombres ?? "") \(cliente.apellidos ?? "")"
            })
        }
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func agregarProductoTapped() {
        let alert = UIAlertController(title: "Agregar Producto", message: nil, preferredStyle: .actionSheet)
        for producto in productos where producto.stock > 0 {
            alert.addAction(UIAlertAction(title: "\(producto.nombre ?? "") - S/ \(String(format: "%.2f", producto.precio)) (Stock: \(producto.stock))", style: .default) { _ in
                self.pedirCantidad(producto: producto)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    private func pedirCantidad(producto: Producto) {
        let alert = UIAlertController(title: "Cantidad", message: "Producto: \(producto.nombre ?? "")\nStock disponible: \(producto.stock)", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Cantidad"
            tf.keyboardType = .numberPad
        }
        alert.addAction(UIAlertAction(title: "Agregar", style: .default) { _ in
            let cantidadStr = alert.textFields?.first?.text ?? ""
            guard let cantidad = Int(cantidadStr), cantidad > 0, cantidad <= producto.stock else {
                self.errorLabel.text = "Cantidad inválida o excede el stock"
                return
            }
            if let idx = self.itemsCarrito.firstIndex(where: { $0.producto.idProducto == producto.idProducto }) {
                let nuevaCant = self.itemsCarrito[idx].cantidad + cantidad
                if nuevaCant > producto.stock {
                    self.errorLabel.text = "Stock insuficiente para \(producto.nombre ?? "")"
                    return
                }
                self.itemsCarrito[idx].cantidad = nuevaCant
            } else {
                self.itemsCarrito.append(ItemCarrito(producto: producto, cantidad: cantidad, precioUnitario: producto.precio))
            }
            self.errorLabel.text = ""
            self.actualizarTotales()
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func registrarTapped() {
        guard let cliente = clienteSeleccionado else {
            errorLabel.text = "Selecciona un cliente"
            return
        }
        guard !itemsCarrito.isEmpty else {
            errorLabel.text = "Agrega al menos un producto"
            return
        }

        let productosVenta = itemsCarrito.map { ($0.producto, $0.cantidad) }
        if viewModel.crear(cliente: cliente, productos: productosVenta) {
            navigationController?.popViewController(animated: true)
        } else {
            errorLabel.text = viewModel.errorMessage
        }
    }

    @objc private func cancelarTapped() {
        navigationController?.popViewController(animated: true)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension VentaFormViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsCarrito.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CarritoCell.identifier, for: indexPath) as! CarritoCell
        cell.configure(with: itemsCarrito[indexPath.row])
        cell.onDelete = { [weak self] in
            self?.itemsCarrito.remove(at: indexPath.row)
            self?.actualizarTotales()
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

// MARK: - CarritoCell
class CarritoCell: UITableViewCell {

    static let identifier = "CarritoCell"

    var onDelete: (() -> Void)?

    private let cardView       = UIView()
    private let nombreLabel    = UILabel()
    private let cantidadLabel  = UILabel()
    private let precioLabel    = UILabel()
    private let subtotalLabel  = UILabel()
    private let deleteButton   = UIButton()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle  = .none

        cardView.backgroundColor    = AppColors.surface
        cardView.layer.cornerRadius = 10
        cardView.layer.borderWidth  = 0.5
        cardView.layer.borderColor  = AppColors.primary.withAlphaComponent(0.15).cgColor
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        nombreLabel.font      = .systemFont(ofSize: 14, weight: .semibold)
        nombreLabel.textColor = AppColors.textPrimary
        nombreLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(nombreLabel)

        cantidadLabel.font      = .systemFont(ofSize: 12)
        cantidadLabel.textColor = AppColors.textSecondary
        cantidadLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(cantidadLabel)

        precioLabel.font      = .systemFont(ofSize: 12)
        precioLabel.textColor = AppColors.textSecondary
        precioLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(precioLabel)

        subtotalLabel.font          = .systemFont(ofSize: 15, weight: .bold)
        subtotalLabel.textColor     = AppColors.accent
        subtotalLabel.textAlignment = .right
        subtotalLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(subtotalLabel)

        deleteButton.setTitle("✕", for: .normal)
        deleteButton.setTitleColor(AppColors.danger, for: .normal)
        deleteButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        cardView.addSubview(deleteButton)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            nombreLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            nombreLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            nombreLabel.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -4),

            cantidadLabel.topAnchor.constraint(equalTo: nombreLabel.bottomAnchor, constant: 2),
            cantidadLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),

            precioLabel.topAnchor.constraint(equalTo: nombreLabel.bottomAnchor, constant: 2),
            precioLabel.leadingAnchor.constraint(equalTo: cantidadLabel.trailingAnchor, constant: 8),

            subtotalLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            subtotalLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            deleteButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 4),
            deleteButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -4),
            deleteButton.widthAnchor.constraint(equalToConstant: 28),
            deleteButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    func configure(with item: ItemCarrito) {
        nombreLabel.text   = item.producto.nombre ?? ""
        cantidadLabel.text = "x\(item.cantidad)"
        precioLabel.text   = "S/ \(String(format: "%.2f", item.precioUnitario))"
        subtotalLabel.text = "S/ \(String(format: "%.2f", item.subtotal))"
    }

    @objc private func deleteTapped() {
        onDelete?()
    }
}

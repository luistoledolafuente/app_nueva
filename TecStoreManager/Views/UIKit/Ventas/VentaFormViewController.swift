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
    private let clienteLabel    = UILabel()
    private let clienteField    = UITextField()
    private let prodLabel       = UILabel()
    private let tableView       = UITableView()
    private let agregarButton   = UIButton()
    private let cardView        = UIView()
    private let subtotalTitle   = UILabel()
    private let subtotalLabel   = UILabel()
    private let igvTitle        = UILabel()
    private let igvLabel        = UILabel()
    private let totalTitle      = UILabel()
    private let totalLabel      = UILabel()
    private let errorLabel      = UILabel()
    private let registrarButton = UIButton()
    private let cancelarButton  = UIButton()

    private var contentHeightConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupActions()
        setupTableView()
        cargarDatos()
        layoutContenido()
    }

    // MARK: - Setup inicial (una sola vez)
    private func setupViews() {
        view.backgroundColor = AppColors.background
        title = "Nueva Venta"
        navigationController?.navigationBar.tintColor = AppColors.accent

        clienteLabel.text = "Cliente"
        clienteLabel.font = .systemFont(ofSize: 13, weight: .medium)
        clienteLabel.textColor = AppColors.textSecondary

        setupTextField(clienteField, placeholder: "Seleccionar cliente")

        prodLabel.text = "Productos"
        prodLabel.font = .systemFont(ofSize: 13, weight: .medium)
        prodLabel.textColor = AppColors.textSecondary

        agregarButton.setTitle("+ Agregar Producto", for: .normal)
        agregarButton.backgroundColor    = AppColors.accent
        agregarButton.setTitleColor(.white, for: .normal)
        agregarButton.titleLabel?.font   = .systemFont(ofSize: 14, weight: .semibold)
        agregarButton.layer.cornerRadius = 10

        cardView.backgroundColor = AppColors.surface
        cardView.layer.cornerRadius = 10
        cardView.layer.borderWidth = 0.5
        cardView.layer.borderColor = AppColors.primary.withAlphaComponent(0.15).cgColor

        let titles = ["Subtotal", "IGV (18%)", "Total"]
        let labels = [subtotalTitle, igvTitle, totalTitle]
        for (t, l) in zip(titles, labels) {
            l.text = t
            l.font = .systemFont(ofSize: 14)
            l.textColor = AppColors.textSecondary
        }

        for lbl in [subtotalLabel, igvLabel] {
            lbl.font = .systemFont(ofSize: 15, weight: .semibold)
            lbl.textAlignment = .right
        }
        subtotalLabel.textColor = AppColors.textPrimary
        igvLabel.textColor      = AppColors.warning

        totalLabel.font          = .systemFont(ofSize: 20, weight: .bold)
        totalLabel.textColor     = AppColors.success
        totalLabel.textAlignment = .right

        subtotalLabel.text = "S/ 0.00"
        igvLabel.text      = "S/ 0.00"
        totalLabel.text    = "S/ 0.00"

        errorLabel.textColor     = AppColors.danger
        errorLabel.font          = .systemFont(ofSize: 13)
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center

        registrarButton.setTitle("Registrar Venta", for: .normal)
        registrarButton.backgroundColor    = AppColors.primary
        registrarButton.setTitleColor(.white, for: .normal)
        registrarButton.titleLabel?.font   = .systemFont(ofSize: 16, weight: .semibold)
        registrarButton.layer.cornerRadius = 12

        cancelarButton.setTitle("Cancelar", for: .normal)
        cancelarButton.setTitleColor(AppColors.danger, for: .normal)
        cancelarButton.titleLabel?.font = .systemFont(ofSize: 15)
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentHeightConstraint = contentView.heightAnchor.constraint(equalToConstant: 800)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentHeightConstraint
        ])
    }

    private func setupActions() {
        clienteField.addTarget(self, action: #selector(clienteFieldTapped), for: .editingDidBegin)
        agregarButton.addTarget(self, action: #selector(agregarProductoTapped), for: .touchUpInside)
        registrarButton.addTarget(self, action: #selector(registrarTapped), for: .touchUpInside)
        cancelarButton.addTarget(self, action: #selector(cancelarTapped), for: .touchUpInside)
    }

    // MARK: - Layout dinámico (se llama al iniciar y al cambiar items)
    private func layoutContenido() {
        let width = view.frame.width

        // Agregar/remover subvistas de contentView
        let subviews: [UIView] = [
            clienteLabel, clienteField,
            prodLabel, tableView, agregarButton,
            cardView, errorLabel, registrarButton, cancelarButton
        ]
        for sv in subviews {
            if sv.superview !== contentView { contentView.addSubview(sv) }
        }

        var yOffset: CGFloat = 16

        clienteLabel.frame = CGRect(x: 24, y: yOffset, width: width - 48, height: 18)
        yOffset += 24

        clienteField.frame = CGRect(x: 24, y: yOffset, width: width - 48, height: 44)
        yOffset += 60

        prodLabel.frame = CGRect(x: 24, y: yOffset, width: width - 48, height: 18)
        yOffset += 24

        let tableH = min(CGFloat(itemsCarrito.count) * 84 + 8, 300)
        tableView.frame = CGRect(x: 16, y: yOffset, width: width - 32, height: tableH)
        yOffset += tableH + 8

        agregarButton.frame = CGRect(x: 24, y: yOffset, width: width - 48, height: 40)
        yOffset += 56

        cardView.frame = CGRect(x: 16, y: yOffset, width: width - 32, height: 140)

        // Layout dentro de cardView
        let cardSubviews: [UIView] = [
            subtotalTitle, subtotalLabel,
            igvTitle, igvLabel,
            totalTitle, totalLabel
        ]
        for sv in cardSubviews {
            if sv.superview !== cardView { cardView.addSubview(sv) }
        }

        var cy: CGFloat = 12
        let rowW = cardView.frame.width - 160

        subtotalTitle.frame = CGRect(x: 16, y: cy, width: 120, height: 22)
        subtotalLabel.frame = CGRect(x: 140, y: cy, width: rowW, height: 22)
        cy += 30
        igvTitle.frame = CGRect(x: 16, y: cy, width: 120, height: 22)
        igvLabel.frame = CGRect(x: 140, y: cy, width: rowW, height: 22)
        cy += 30
        totalTitle.frame = CGRect(x: 16, y: cy, width: 120, height: 22)
        totalLabel.frame = CGRect(x: 140, y: cy, width: rowW, height: 22)

        yOffset += cardView.frame.height + 16

        errorLabel.frame = CGRect(x: 24, y: yOffset, width: width - 48, height: 20)
        yOffset += 28

        registrarButton.frame = CGRect(x: 24, y: yOffset, width: width - 48, height: 50)
        yOffset += 62

        cancelarButton.frame = CGRect(x: 24, y: yOffset, width: width - 48, height: 40)
        yOffset += 60

        contentHeightConstraint.constant = yOffset
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

        layoutContenido()
        tableView.reloadData()
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

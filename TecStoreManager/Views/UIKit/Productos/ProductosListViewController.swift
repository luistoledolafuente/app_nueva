import UIKit

class ProductosListViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var searchBar:     UISearchBar!
    @IBOutlet weak var filterControl: UISegmentedControl!
    @IBOutlet weak var tableView:     UITableView!
    @IBOutlet weak var addButton:     UIButton!
    @IBOutlet weak var emptyLabel:    UILabel!
    
    let viewModel = ProductoViewModel()
    var productoSeleccionado: Producto?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.cargar()
        tableView.reloadData()
        updateEmptyState()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = AppColors.background
        title = "Productos"
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.tintColor = AppColors.accent
        
        setupSearchBar()
        setupFilterControl()
        setupAddButton()
        setupEmptyLabel()
    }
    
    private func setupSearchBar() {
        searchBar.placeholder = "Buscar producto..."
        searchBar.barTintColor = AppColors.background
        searchBar.searchTextField.backgroundColor = AppColors.surface
        searchBar.searchTextField.textColor = AppColors.textPrimary
        searchBar.searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Buscar producto...",
            attributes: [.foregroundColor: AppColors.textSecondary]
        )
        searchBar.delegate = self
    }
    
    private func setupFilterControl() {
        filterControl.removeAllSegments()
        filterControl.insertSegment(withTitle: "Todos",      at: 0, animated: false)
        filterControl.insertSegment(withTitle: "Stock Bajo", at: 1, animated: false)
        filterControl.selectedSegmentIndex     = 0
        filterControl.backgroundColor          = AppColors.surface
        filterControl.selectedSegmentTintColor = AppColors.primary
        filterControl.setTitleTextAttributes([.foregroundColor: AppColors.textSecondary], for: .normal)
        filterControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }
    
    private func setupAddButton() {
        addButton.setTitle("+ Nuevo Producto", for: .normal)
        addButton.backgroundColor    = AppColors.primary
        addButton.setTitleColor(.white, for: .normal)
        addButton.titleLabel?.font   = .systemFont(ofSize: 15, weight: .semibold)
        addButton.layer.cornerRadius = 12
    }
    
    private func setupEmptyLabel() {
        emptyLabel.text          = "No hay productos registrados"
        emptyLabel.font          = .systemFont(ofSize: 16, weight: .medium)
        emptyLabel.textColor     = AppColors.textSecondary
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden      = true
    }
    
    private func setupTableView() {
        tableView.backgroundColor = AppColors.background
        tableView.separatorStyle  = .none
        tableView.delegate        = self
        tableView.dataSource      = self
        tableView.register(ProductoCell.self, forCellReuseIdentifier: ProductoCell.identifier)
    }
    
    // MARK: - Helpers
    private func updateEmptyState() {
        emptyLabel.isHidden = !viewModel.productos.isEmpty
        tableView.isHidden  = viewModel.productos.isEmpty
    }
    
    // MARK: - Actions
    @IBAction func filterChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 1 {
            viewModel.productos = viewModel.productos.filter { $0.stock <= 5 }
        } else {
            viewModel.cargar()
        }
        tableView.reloadData()
        updateEmptyState()
    }
    
    @IBAction func addTapped(_ sender: UIButton) {
        productoSeleccionado = nil
        performSegue(withIdentifier: "goToProductoForm", sender: nil)
    }
    
    // MARK: - Prepare Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToProductoForm" {
            let vc = segue.destination as! ProductoFormViewController
            vc.producto  = productoSeleccionado
            vc.viewModel = viewModel
        } else if segue.identifier == "goToProductoDetalle" {
            let vc = segue.destination as! ProductoDetalleViewController
            vc.producto  = productoSeleccionado
            vc.viewModel = viewModel
        }
    }
}

// MARK: - UITableViewDataSource
extension ProductosListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.productos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProductoCell.identifier, for: indexPath) as! ProductoCell
        cell.configure(with: viewModel.productos[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alert = UIAlertController(title: "Eliminar", message: "¿Eliminar este producto?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
            alert.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { _ in
                self.viewModel.eliminar(self.viewModel.productos[indexPath.row])
                self.tableView.reloadData()
                self.updateEmptyState()
            })
            present(alert, animated: true)
        }
    }
}

// MARK: - UITableViewDelegate
extension ProductosListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        productoSeleccionado = viewModel.productos[indexPath.row]
        performSegue(withIdentifier: "goToProductoDetalle", sender: nil)
    }
}

// MARK: - UISearchBarDelegate
extension ProductosListViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchText = searchText
        viewModel.buscar()
        tableView.reloadData()
        updateEmptyState()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - ProductoCell
class ProductoCell: UITableViewCell {
    
    static let identifier = "ProductoCell"
    
    private let cardView       = UIView()
    private let nombreLabel    = UILabel()
    private let categoriaLabel = UILabel()
    private let precioLabel    = UILabel()
    private let stockBadge     = UIView()
    private let stockLabel     = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle  = .none
        
        cardView.backgroundColor    = AppColors.surface
        cardView.layer.cornerRadius = 12
        cardView.layer.borderWidth  = 0.5
        cardView.layer.borderColor  = AppColors.primary.withAlphaComponent(0.2).cgColor
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        
        nombreLabel.font      = .systemFont(ofSize: 15, weight: .semibold)
        nombreLabel.textColor = AppColors.textPrimary
        nombreLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(nombreLabel)
        
        categoriaLabel.font      = .systemFont(ofSize: 12)
        categoriaLabel.textColor = AppColors.textSecondary
        categoriaLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(categoriaLabel)
        
        precioLabel.font      = .systemFont(ofSize: 14, weight: .semibold)
        precioLabel.textColor = AppColors.accent
        precioLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(precioLabel)
        
        stockBadge.layer.cornerRadius = 8
        stockBadge.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(stockBadge)
        
        stockLabel.font          = .systemFont(ofSize: 12, weight: .semibold)
        stockLabel.textAlignment = .center
        stockLabel.translatesAutoresizingMaskIntoConstraints = false
        stockBadge.addSubview(stockLabel)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            nombreLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            nombreLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            nombreLabel.trailingAnchor.constraint(equalTo: stockBadge.leadingAnchor, constant: -8),
            
            categoriaLabel.topAnchor.constraint(equalTo: nombreLabel.bottomAnchor, constant: 4),
            categoriaLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            
            precioLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),
            precioLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            
            stockBadge.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            stockBadge.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            stockBadge.widthAnchor.constraint(equalToConstant: 80),
            stockBadge.heightAnchor.constraint(equalToConstant: 32),
            
            stockLabel.centerXAnchor.constraint(equalTo: stockBadge.centerXAnchor),
            stockLabel.centerYAnchor.constraint(equalTo: stockBadge.centerYAnchor)
        ])
    }
    
    func configure(with producto: Producto) {
        nombreLabel.text    = producto.nombre
        categoriaLabel.text = producto.categoria
        precioLabel.text    = "S/ \(String(format: "%.2f", producto.precio))"
        
        let stock = Int(producto.stock)
        stockLabel.text = "Stock: \(stock)"
        
        if stock <= 5 {
            stockBadge.backgroundColor = AppColors.danger.withAlphaComponent(0.15)
            stockLabel.textColor       = AppColors.danger
        } else if stock <= 15 {
            stockBadge.backgroundColor = AppColors.warning.withAlphaComponent(0.15)
            stockLabel.textColor       = AppColors.warning
        } else {
            stockBadge.backgroundColor = AppColors.success.withAlphaComponent(0.15)
            stockLabel.textColor       = AppColors.success
        }
    }
}

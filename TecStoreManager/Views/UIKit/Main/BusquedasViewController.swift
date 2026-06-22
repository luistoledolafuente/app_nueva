import UIKit

class BusquedasViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var searchBar:     UISearchBar!
    @IBOutlet weak var filterControl: UISegmentedControl!
    @IBOutlet weak var tableView:     UITableView!
    @IBOutlet weak var emptyLabel:    UILabel!
    
    private let productoVM = ProductoViewModel()
    private let clienteVM  = ClienteViewModel()
    private let ventaVM    = VentaViewModel()
    
    private var tabSeleccion = 0
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = AppColors.background
        title = "Busquedas"
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.tintColor = AppColors.accent
        
        setupSearchBar()
        setupFilterControl()
        setupEmptyLabel()
    }
    
    private func setupSearchBar() {
        searchBar.placeholder = "Buscar producto por nombre..."
        searchBar.barTintColor = AppColors.background
        searchBar.searchTextField.backgroundColor = AppColors.surface
        searchBar.searchTextField.textColor = AppColors.textPrimary
        searchBar.searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Buscar...",
            attributes: [.foregroundColor: AppColors.textSecondary]
        )
        searchBar.delegate = self
    }
    
    private func setupFilterControl() {
        filterControl.removeAllSegments()
        filterControl.insertSegment(withTitle: "Productos", at: 0, animated: false)
        filterControl.insertSegment(withTitle: "Clientes",  at: 1, animated: false)
        filterControl.insertSegment(withTitle: "Ventas",    at: 2, animated: false)
        filterControl.selectedSegmentIndex     = 0
        filterControl.backgroundColor          = AppColors.surface
        filterControl.selectedSegmentTintColor = AppColors.primary
        filterControl.setTitleTextAttributes([.foregroundColor: AppColors.textSecondary], for: .normal)
        filterControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }
    
    private func setupEmptyLabel() {
        emptyLabel.text          = "Escribe para buscar"
        emptyLabel.font          = .systemFont(ofSize: 16, weight: .medium)
        emptyLabel.textColor     = AppColors.textSecondary
        emptyLabel.textAlignment = .center
    }
    
    private func setupTableView() {
        tableView.backgroundColor = AppColors.background
        tableView.separatorStyle  = .none
        tableView.delegate        = self
        tableView.dataSource      = self
        tableView.register(BusquedaCell.self, forCellReuseIdentifier: BusquedaCell.identifier)
    }
    
    private func updateEmptyState() {
        let count = resultCount()
        emptyLabel.isHidden = count > 0
        tableView.isHidden  = count == 0
    }
    
    private func resultCount() -> Int {
        switch tabSeleccion {
        case 0: return productoVM.productos.count
        case 1: return clienteVM.clientes.count
        case 2: return ventaVM.ventas.count
        default: return 0
        }
    }
    
    private func buscar(_ text: String) {
        switch tabSeleccion {
        case 0:
            productoVM.searchText = text
            productoVM.buscar()
        case 1:
            clienteVM.searchText = text
            if text.count == 8 && text.allSatisfy({ $0.isNumber }) {
                clienteVM.buscarPorDNI()
            } else {
                clienteVM.buscarPorNombre()
            }
        case 2:
            ventaVM.searchText = text
            ventaVM.buscarPorCliente()
        default: break
        }
        tableView.reloadData()
        updateEmptyState()
    }
    
    // MARK: - Actions
    @IBAction func filterChanged(_ sender: UISegmentedControl) {
        tabSeleccion = sender.selectedSegmentIndex
        switch tabSeleccion {
        case 0: searchBar.placeholder = "Buscar producto por nombre..."
        case 1: searchBar.placeholder = "Buscar cliente por nombre o DNI..."
        case 2: searchBar.placeholder = "Buscar venta por cliente..."
        default: break
        }
        searchBar.text = ""
        tableView.reloadData()
        updateEmptyState()
    }
}

// MARK: - UITableViewDataSource
extension BusquedasViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BusquedaCell.identifier, for: indexPath) as! BusquedaCell
        
        switch tabSeleccion {
        case 0:
            let p = productoVM.productos[indexPath.row]
            cell.configure(
                titulo:    p.nombre ?? "",
                subtitulo: p.categoria ?? "",
                valor:     "S/ \(String(format: "%.2f", p.precio))",
                badge:     "Stock: \(p.stock)",
                badgeColor: p.stock <= 5 ? AppColors.danger : AppColors.success
            )
        case 1:
            let c = clienteVM.clientes[indexPath.row]
            cell.configure(
                titulo:    "\(c.nombres ?? "") \(c.apellidos ?? "")",
                subtitulo: "DNI: \(c.dni ?? "")",
                valor:     c.correo ?? "",
                badge:     c.estado ? "Activo" : "Inactivo",
                badgeColor: c.estado ? AppColors.success : AppColors.danger
            )
        case 2:
            let v = ventaVM.ventas[indexPath.row]
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            cell.configure(
                titulo:    "\(v.cliente?.nombres ?? "") \(v.cliente?.apellidos ?? "")",
                subtitulo: v.producto?.nombre ?? "",
                valor:     "S/ \(String(format: "%.2f", v.total))",
                badge:     formatter.string(from: v.fechaVenta ?? Date()),
                badgeColor: AppColors.primary
            )
        default: break
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension BusquedasViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
}

// MARK: - UISearchBarDelegate
extension BusquedasViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        buscar(searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - BusquedaCell
class BusquedaCell: UITableViewCell {
    
    static let identifier = "BusquedaCell"
    
    private let cardView      = UIView()
    private let tituloLabel   = UILabel()
    private let subtituloLabel = UILabel()
    private let valorLabel    = UILabel()
    private let badgeView     = UIView()
    private let badgeLabel    = UILabel()
    
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
        
        tituloLabel.font      = .systemFont(ofSize: 15, weight: .semibold)
        tituloLabel.textColor = AppColors.textPrimary
        tituloLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(tituloLabel)
        
        subtituloLabel.font      = .systemFont(ofSize: 12)
        subtituloLabel.textColor = AppColors.textSecondary
        subtituloLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(subtituloLabel)
        
        valorLabel.font          = .systemFont(ofSize: 14, weight: .semibold)
        valorLabel.textColor     = AppColors.accent
        valorLabel.textAlignment = .right
        valorLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(valorLabel)
        
        badgeView.layer.cornerRadius = 8
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(badgeView)
        
        badgeLabel.font          = .systemFont(ofSize: 11, weight: .semibold)
        badgeLabel.textAlignment = .center
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeView.addSubview(badgeLabel)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            tituloLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            tituloLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            tituloLabel.trailingAnchor.constraint(equalTo: valorLabel.leadingAnchor, constant: -8),
            
            subtituloLabel.topAnchor.constraint(equalTo: tituloLabel.bottomAnchor, constant: 4),
            subtituloLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            
            valorLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            valorLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            valorLabel.widthAnchor.constraint(equalToConstant: 100),
            
            badgeView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            badgeView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            badgeView.heightAnchor.constraint(equalToConstant: 24),
            
            badgeLabel.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            badgeLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
            badgeLabel.leadingAnchor.constraint(equalTo: badgeView.leadingAnchor, constant: 8),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: -8)
        ])
    }
    
    func configure(titulo: String, subtitulo: String, valor: String, badge: String, badgeColor: UIColor) {
        tituloLabel.text    = titulo
        subtituloLabel.text = subtitulo
        valorLabel.text     = valor
        badgeLabel.text     = badge
        badgeView.backgroundColor = badgeColor.withAlphaComponent(0.15)
        badgeLabel.textColor      = badgeColor
    }
}

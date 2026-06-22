import UIKit

class VentasListViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var totalLabel:  UILabel!
    @IBOutlet weak var countLabel:  UILabel!
    @IBOutlet weak var searchBar:   UISearchBar!
    @IBOutlet weak var tableView:   UITableView!
    @IBOutlet weak var addButton:   UIButton!
    @IBOutlet weak var emptyLabel:  UILabel!
    
    let viewModel = VentaViewModel()
    
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
        updateTotales()
        updateEmptyState()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = AppColors.background
        title = "Ventas"
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.tintColor = AppColors.accent
        
        setupTotalCard()
        setupSearchBar()
        setupAddButton()
        setupEmptyLabel()
    }
    
    private func setupTotalCard() {
        totalLabel.font      = .systemFont(ofSize: 22, weight: .bold)
        totalLabel.textColor = AppColors.success
        
        countLabel.font      = .systemFont(ofSize: 12)
        countLabel.textColor = AppColors.textSecondary
    }
    
    private func setupSearchBar() {
        searchBar.placeholder = "Buscar por cliente..."
        searchBar.barTintColor = AppColors.background
        searchBar.searchTextField.backgroundColor = AppColors.surface
        searchBar.searchTextField.textColor = AppColors.textPrimary
        searchBar.searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Buscar por cliente...",
            attributes: [.foregroundColor: AppColors.textSecondary]
        )
        searchBar.delegate = self
    }
    
    private func setupAddButton() {
        addButton.setTitle("+ Nueva Venta", for: .normal)
        addButton.backgroundColor    = AppColors.primary
        addButton.setTitleColor(.white, for: .normal)
        addButton.titleLabel?.font   = .systemFont(ofSize: 15, weight: .semibold)
        addButton.layer.cornerRadius = 12
    }
    
    private func setupEmptyLabel() {
        emptyLabel.text          = "No hay ventas registradas"
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
        tableView.register(VentaCell.self, forCellReuseIdentifier: VentaCell.identifier)
    }
    
    // MARK: - Helpers
    private func updateEmptyState() {
        emptyLabel.isHidden = !viewModel.ventas.isEmpty
        tableView.isHidden  = viewModel.ventas.isEmpty
    }
    
    private func updateTotales() {
        totalLabel.text = "S/ \(String(format: "%.2f", viewModel.montoTotalVendido()))"
        countLabel.text = "\(viewModel.totalVentas()) ventas"
    }
    
    // MARK: - Actions
    @IBAction func addTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "goToVentaForm", sender: nil)
    }
    
    // MARK: - Prepare Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToVentaForm" {
            let vc = segue.destination as! VentaFormViewController
            vc.viewModel = viewModel
        }
    }
}

// MARK: - UITableViewDataSource
extension VentasListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.ventas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: VentaCell.identifier, for: indexPath) as! VentaCell
        cell.configure(with: viewModel.ventas[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alert = UIAlertController(title: "Eliminar", message: "¿Eliminar esta venta?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
            alert.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { _ in
                self.viewModel.eliminar(self.viewModel.ventas[indexPath.row])
                self.tableView.reloadData()
                self.updateTotales()
                self.updateEmptyState()
            })
            present(alert, animated: true)
        }
    }
}

// MARK: - UITableViewDelegate
extension VentasListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension VentasListViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchText = searchText
        viewModel.buscarPorCliente()
        tableView.reloadData()
        updateEmptyState()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - VentaCell
class VentaCell: UITableViewCell {
    
    static let identifier = "VentaCell"
    
    private let cardView      = UIView()
    private let clienteLabel  = UILabel()
    private let productoLabel = UILabel()
    private let fechaLabel    = UILabel()
    private let cantidadLabel = UILabel()
    private let totalLabel    = UILabel()
    
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
        cardView.layer.borderColor  = UIColor(hex: "#059669").withAlphaComponent(0.2).cgColor
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        
        clienteLabel.font      = .systemFont(ofSize: 15, weight: .semibold)
        clienteLabel.textColor = AppColors.textPrimary
        clienteLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(clienteLabel)
        
        productoLabel.font      = .systemFont(ofSize: 12)
        productoLabel.textColor = AppColors.textSecondary
        productoLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(productoLabel)
        
        fechaLabel.font      = .systemFont(ofSize: 11)
        fechaLabel.textColor = AppColors.textSecondary
        fechaLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(fechaLabel)
        
        cantidadLabel.font      = .systemFont(ofSize: 12, weight: .medium)
        cantidadLabel.textColor = AppColors.textSecondary
        cantidadLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(cantidadLabel)
        
        totalLabel.font          = .systemFont(ofSize: 18, weight: .bold)
        totalLabel.textColor     = AppColors.success
        totalLabel.textAlignment = .right
        totalLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(totalLabel)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            clienteLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            clienteLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            clienteLabel.trailingAnchor.constraint(equalTo: totalLabel.leadingAnchor, constant: -8),
            
            productoLabel.topAnchor.constraint(equalTo: clienteLabel.bottomAnchor, constant: 4),
            productoLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            
            fechaLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),
            fechaLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            
            cantidadLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),
            cantidadLabel.leadingAnchor.constraint(equalTo: fechaLabel.trailingAnchor, constant: 12),
            
            totalLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            totalLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            totalLabel.widthAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    func configure(with venta: Venta) {
        clienteLabel.text  = "\(venta.cliente?.nombres ?? "") \(venta.cliente?.apellidos ?? "")"
        productoLabel.text = venta.producto?.nombre ?? ""
        cantidadLabel.text = "Cant: \(venta.cantidad)"
        totalLabel.text    = "S/ \(String(format: "%.2f", venta.total))"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        fechaLabel.text = formatter.string(from: venta.fechaVenta ?? Date())
    }
}

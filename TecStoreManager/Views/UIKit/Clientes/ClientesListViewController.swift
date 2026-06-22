import UIKit

class ClientesListViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var searchBar:     UISearchBar!
    @IBOutlet weak var filterControl: UISegmentedControl!
    @IBOutlet weak var tableView:     UITableView!
    @IBOutlet weak var addButton:     UIButton!
    @IBOutlet weak var emptyLabel:    UILabel!
    
    let viewModel = ClienteViewModel()
    var clienteSeleccionado: Cliente?
    
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
        title = "Clientes"
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.tintColor = AppColors.accent
        
        setupSearchBar()
        setupFilterControl()
        setupAddButton()
        setupEmptyLabel()
    }
    
    private func setupSearchBar() {
        searchBar.placeholder = "Buscar por nombre o DNI..."
        searchBar.barTintColor = AppColors.background
        searchBar.searchTextField.backgroundColor = AppColors.surface
        searchBar.searchTextField.textColor = AppColors.textPrimary
        searchBar.searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Buscar por nombre o DNI...",
            attributes: [.foregroundColor: AppColors.textSecondary]
        )
        searchBar.delegate = self
    }
    
    private func setupFilterControl() {
        filterControl.removeAllSegments()
        filterControl.insertSegment(withTitle: "Todos",     at: 0, animated: false)
        filterControl.insertSegment(withTitle: "Activos",   at: 1, animated: false)
        filterControl.insertSegment(withTitle: "Inactivos", at: 2, animated: false)
        filterControl.selectedSegmentIndex     = 0
        filterControl.backgroundColor          = AppColors.surface
        filterControl.selectedSegmentTintColor = AppColors.primary
        filterControl.setTitleTextAttributes([.foregroundColor: AppColors.textSecondary], for: .normal)
        filterControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }
    
    private func setupAddButton() {
        addButton.setTitle("+ Nuevo Cliente", for: .normal)
        addButton.backgroundColor    = AppColors.primary
        addButton.setTitleColor(.white, for: .normal)
        addButton.titleLabel?.font   = .systemFont(ofSize: 15, weight: .semibold)
        addButton.layer.cornerRadius = 12
    }
    
    private func setupEmptyLabel() {
        emptyLabel.text          = "No hay clientes registrados"
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
        tableView.register(ClienteCell.self, forCellReuseIdentifier: ClienteCell.identifier)
    }
    
    // MARK: - Helpers
    private func updateEmptyState() {
        emptyLabel.isHidden = !viewModel.clientes.isEmpty
        tableView.isHidden  = viewModel.clientes.isEmpty
    }
    
    // MARK: - Actions
    @IBAction func filterChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 1: viewModel.filtrarPorEstado(true)
        case 2: viewModel.filtrarPorEstado(false)
        default: viewModel.cargar()
        }
        tableView.reloadData()
        updateEmptyState()
    }
    
    @IBAction func addTapped(_ sender: UIButton) {
        clienteSeleccionado = nil
        performSegue(withIdentifier: "goToClienteForm", sender: nil)
    }
    
    // MARK: - Prepare Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToClienteForm" {
            let vc = segue.destination as! ClienteFormViewController
            vc.cliente   = clienteSeleccionado
            vc.viewModel = viewModel
        } else if segue.identifier == "goToClienteDetalle" {
            let vc = segue.destination as! ClienteDetalleViewController
            vc.cliente   = clienteSeleccionado
            vc.viewModel = viewModel
        }
    }
}

// MARK: - UITableViewDataSource
extension ClientesListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.clientes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ClienteCell.identifier, for: indexPath) as! ClienteCell
        cell.configure(with: viewModel.clientes[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alert = UIAlertController(title: "Eliminar", message: "¿Eliminar este cliente?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
            alert.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { _ in
                self.viewModel.eliminar(self.viewModel.clientes[indexPath.row])
                self.tableView.reloadData()
                self.updateEmptyState()
            })
            present(alert, animated: true)
        }
    }
}

// MARK: - UITableViewDelegate
extension ClientesListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        clienteSeleccionado = viewModel.clientes[indexPath.row]
        performSegue(withIdentifier: "goToClienteDetalle", sender: nil)
    }
}

// MARK: - UISearchBarDelegate
extension ClientesListViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchText = searchText
        if searchText.count == 8 && searchText.allSatisfy({ $0.isNumber }) {
            viewModel.buscarPorDNI()
        } else {
            viewModel.buscarPorNombre()
        }
        tableView.reloadData()
        updateEmptyState()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - ClienteCell
class ClienteCell: UITableViewCell {
    
    static let identifier = "ClienteCell"
    
    private let cardView      = UIView()
    private let avatarView    = UIView()
    private let avatarLabel   = UILabel()
    private let nombreLabel   = UILabel()
    private let dniLabel      = UILabel()
    private let correoLabel   = UILabel()
    private let estadoBadge   = UIView()
    private let estadoLabel   = UILabel()
    
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
        cardView.layer.borderColor  = UIColor(hex: "#0891B2").withAlphaComponent(0.2).cgColor
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        
        avatarView.backgroundColor    = AppColors.primary.withAlphaComponent(0.15)
        avatarView.layer.cornerRadius = 22
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(avatarView)
        
        avatarLabel.font          = .systemFont(ofSize: 18, weight: .bold)
        avatarLabel.textColor     = AppColors.accent
        avatarLabel.textAlignment = .center
        avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(avatarLabel)
        
        nombreLabel.font      = .systemFont(ofSize: 15, weight: .semibold)
        nombreLabel.textColor = AppColors.textPrimary
        nombreLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(nombreLabel)
        
        dniLabel.font      = .systemFont(ofSize: 12)
        dniLabel.textColor = AppColors.textSecondary
        dniLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(dniLabel)
        
        correoLabel.font      = .systemFont(ofSize: 12)
        correoLabel.textColor = AppColors.textSecondary
        correoLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(correoLabel)
        
        estadoBadge.layer.cornerRadius = 8
        estadoBadge.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(estadoBadge)
        
        estadoLabel.font          = .systemFont(ofSize: 11, weight: .semibold)
        estadoLabel.textAlignment = .center
        estadoLabel.translatesAutoresizingMaskIntoConstraints = false
        estadoBadge.addSubview(estadoLabel)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            avatarView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            avatarView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            avatarView.widthAnchor.constraint(equalToConstant: 44),
            avatarView.heightAnchor.constraint(equalToConstant: 44),
            
            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            
            nombreLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            nombreLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            nombreLabel.trailingAnchor.constraint(equalTo: estadoBadge.leadingAnchor, constant: -8),
            
            dniLabel.topAnchor.constraint(equalTo: nombreLabel.bottomAnchor, constant: 3),
            dniLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            
            correoLabel.topAnchor.constraint(equalTo: dniLabel.bottomAnchor, constant: 3),
            correoLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            correoLabel.trailingAnchor.constraint(equalTo: estadoBadge.leadingAnchor, constant: -8),
            
            estadoBadge.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            estadoBadge.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            estadoBadge.widthAnchor.constraint(equalToConstant: 60),
            estadoBadge.heightAnchor.constraint(equalToConstant: 28),
            
            estadoLabel.centerXAnchor.constraint(equalTo: estadoBadge.centerXAnchor),
            estadoLabel.centerYAnchor.constraint(equalTo: estadoBadge.centerYAnchor)
        ])
    }
    
    func configure(with cliente: Cliente) {
        avatarLabel.text = String(cliente.nombres?.prefix(1) ?? "?")
        nombreLabel.text = "\(cliente.nombres ?? "") \(cliente.apellidos ?? "")"
        dniLabel.text    = "DNI: \(cliente.dni ?? "")"
        correoLabel.text = cliente.correo
        
        if cliente.estado {
            estadoBadge.backgroundColor = AppColors.success.withAlphaComponent(0.15)
            estadoLabel.textColor       = AppColors.success
            estadoLabel.text            = "Activo"
        } else {
            estadoBadge.backgroundColor = AppColors.danger.withAlphaComponent(0.15)
            estadoLabel.textColor       = AppColors.danger
            estadoLabel.text            = "Inactivo"
        }
    }
}

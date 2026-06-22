import UIKit
import SwiftUI

class MenuViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var welcomeLabel:   UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var usuarioNombre: String = "Usuario"
    
    private let menuItems: [(title: String, subtitle: String, color: UIColor)] = [
        ("Productos",     "Gestión de inventario",   UIColor(hex: "#4F46E5")),
        ("Clientes",      "Base de clientes",        UIColor(hex: "#0891B2")),
        ("Ventas",        "Registro de ventas",      UIColor(hex: "#059669")),
        ("Búsquedas",     "Buscar registros",        UIColor(hex: "#7C3AED")),
        ("Mapa",          "Ubicación GPS",           UIColor(hex: "#DC2626")),
        ("Reportes",      "Estadísticas",            UIColor(hex: "#D97706")),
        ("Configuración", "Ajustes de la app",       UIColor(hex: "#475569")),
        ("Acerca de",     "Información del sistema", UIColor(hex: "#0F766E"))
    ]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = AppColors.background
        navigationController?.navigationBar.isHidden = true

        welcomeLabel.text      = "Bienvenido 👋"
        welcomeLabel.font      = .systemFont(ofSize: 26, weight: .bold)
        welcomeLabel.textColor = AppColors.accent
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing      = 16
        layout.sectionInset            = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        let width = (collectionView.frame.width - 48) / 2
        layout.itemSize = CGSize(width: width, height: 130)
        
        collectionView.collectionViewLayout = layout
        collectionView.backgroundColor      = AppColors.background
        collectionView.delegate             = self
        collectionView.dataSource           = self
        collectionView.register(MenuCell.self, forCellWithReuseIdentifier: MenuCell.identifier)
    }
    
    // MARK: - Actions
    @IBAction func logoutTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Cerrar sesión", message: "¿Estás seguro?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Salir", style: .destructive) { _ in
            self.navigationController?.popToRootViewController(animated: true)
        })
        present(alert, animated: true)
    }
    
    private func navegarA(_ title: String) {
        let swiftUIView: AnyView
        switch title {
        case "Productos":    swiftUIView = AnyView(ProductosSwiftUIView())
        case "Clientes":     swiftUIView = AnyView(ClientesSwiftUIView())
        case "Ventas":       swiftUIView = AnyView(VentasSwiftUIView())
        case "Búsquedas":   swiftUIView = AnyView(BusquedasSwiftUIView())
        case "Mapa":         swiftUIView = AnyView(MapaSwiftUIView())
        case "Reportes":     swiftUIView = AnyView(ReportesSwiftUIView())
        case "Configuración": swiftUIView = AnyView(ConfiguracionSwiftUIView())
        case "Acerca de":    swiftUIView = AnyView(AcercaDeSwiftUIView())
        default:             return
        }

        let hostingVC = UIHostingController(rootView: swiftUIView)
        hostingVC.title = title
        hostingVC.navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.isHidden = false
        navigationController?.pushViewController(hostingVC, animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension MenuViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MenuCell.identifier, for: indexPath) as! MenuCell
        let item = menuItems[indexPath.row]
        cell.configure(title: item.title, subtitle: item.subtitle, color: item.color)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension MenuViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        navegarA(menuItems[indexPath.row].title)
    }
}

// MARK: - MenuCell
class MenuCell: UICollectionViewCell {
    
    static let identifier = "MenuCell"
    
    private let iconView      = UIView()
    private let iconLabel     = UILabel()
    private let titleLabel    = UILabel()
    private let subtitleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        contentView.backgroundColor    = AppColors.surface
        contentView.layer.cornerRadius = 16
        contentView.layer.borderWidth  = 0.5
        contentView.layer.borderColor  = AppColors.primary.withAlphaComponent(0.3).cgColor
        
        iconView.layer.cornerRadius = 12
        iconView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)
        
        iconLabel.font          = .systemFont(ofSize: 22, weight: .bold)
        iconLabel.textAlignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        iconView.addSubview(iconLabel)
        
        titleLabel.font      = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = AppColors.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        subtitleLabel.font          = .systemFont(ofSize: 11)
        subtitleLabel.textColor     = AppColors.textSecondary
        subtitleLabel.numberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44),
            
            iconLabel.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])
    }
    
    func configure(title: String, subtitle: String, color: UIColor) {
        iconLabel.text                = String(title.prefix(1))
        iconLabel.textColor           = color
        iconView.backgroundColor      = color.withAlphaComponent(0.15)
        contentView.layer.borderColor = color.withAlphaComponent(0.3).cgColor
        titleLabel.text               = title
        subtitleLabel.text            = subtitle
    }
}

import UIKit

class ProductoDetalleViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var nombreLabel:    UILabel!
    @IBOutlet weak var categoriaLabel: UILabel!
    @IBOutlet weak var precioLabel:    UILabel!
    @IBOutlet weak var stockLabel:     UILabel!
    @IBOutlet weak var codigoLabel:    UILabel!
    @IBOutlet weak var fechaLabel:     UILabel!
    @IBOutlet weak var estadoLabel:    UILabel!
    @IBOutlet weak var editarButton:   UIButton!
    @IBOutlet weak var eliminarButton: UIButton!
    
    var producto: Producto?
    var viewModel = ProductoViewModel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        cargarDatos()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = AppColors.background
        title = "Detalle Producto"
        navigationController?.navigationBar.tintColor = AppColors.accent

        view.addCard(frame: CGRect(x: 16, y: 158, width: view.frame.width - 32, height: 394))

        nombreLabel.font          = .systemFont(ofSize: 22, weight: .bold)
        nombreLabel.textColor     = AppColors.textPrimary
        nombreLabel.numberOfLines = 0
        
        categoriaLabel.font      = .systemFont(ofSize: 14)
        categoriaLabel.textColor = AppColors.textSecondary
        
        precioLabel.font      = .systemFont(ofSize: 20, weight: .bold)
        precioLabel.textColor = AppColors.accent
        
        stockLabel.font      = .systemFont(ofSize: 14, weight: .semibold)
        stockLabel.textColor = AppColors.success
        
        codigoLabel.font      = .systemFont(ofSize: 14)
        codigoLabel.textColor = AppColors.textSecondary
        
        fechaLabel.font      = .systemFont(ofSize: 13)
        fechaLabel.textColor = AppColors.textSecondary
        
        estadoLabel.font      = .systemFont(ofSize: 13, weight: .semibold)
        estadoLabel.textColor = AppColors.success
        
        editarButton.setTitle("Editar", for: .normal)
        editarButton.backgroundColor    = AppColors.primary
        editarButton.setTitleColor(.white, for: .normal)
        editarButton.titleLabel?.font   = .systemFont(ofSize: 16, weight: .semibold)
        editarButton.layer.cornerRadius = 12
        
        eliminarButton.setTitle("Eliminar", for: .normal)
        eliminarButton.backgroundColor    = AppColors.danger
        eliminarButton.setTitleColor(.white, for: .normal)
        eliminarButton.titleLabel?.font   = .systemFont(ofSize: 16, weight: .semibold)
        eliminarButton.layer.cornerRadius = 12
    }
    
    private func cargarDatos() {
        guard let p = producto else { return }
        nombreLabel.text    = p.nombre
        categoriaLabel.text = p.categoria
        precioLabel.text    = "S/ \(String(format: "%.2f", p.precio))"
        codigoLabel.text    = "Codigo: \(p.codigo ?? "")"
        estadoLabel.text    = p.estado ? "Activo" : "Inactivo"
        estadoLabel.textColor = p.estado ? AppColors.success : AppColors.danger
        
        let stock = Int(p.stock)
        stockLabel.text = "Stock: \(stock) unidades"
        if stock <= 5 {
            stockLabel.textColor = AppColors.danger
        } else if stock <= 15 {
            stockLabel.textColor = AppColors.warning
        } else {
            stockLabel.textColor = AppColors.success
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        fechaLabel.text = "Registrado: \(formatter.string(from: p.fechaRegistro ?? Date()))"
    }
    
    // MARK: - Actions
    @IBAction func editarTapped(_ sender: UIButton) {
        let vc = storyboard?.instantiateViewController(identifier: "ProductoFormViewController") as! ProductoFormViewController
        vc.producto  = producto
        vc.viewModel = viewModel
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func eliminarTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Eliminar", message: "¿Eliminar este producto?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { _ in
            if let p = self.producto {
                self.viewModel.eliminar(p)
                self.navigationController?.popViewController(animated: true)
            }
        })
        present(alert, animated: true)
    }
}

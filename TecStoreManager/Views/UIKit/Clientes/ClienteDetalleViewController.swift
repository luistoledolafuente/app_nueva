import UIKit

class ClienteDetalleViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var nombreLabel:    UILabel!
    @IBOutlet weak var dniLabel:       UILabel!
    @IBOutlet weak var telefonoLabel:  UILabel!
    @IBOutlet weak var correoLabel:    UILabel!
    @IBOutlet weak var direccionLabel: UILabel!
    @IBOutlet weak var estadoLabel:    UILabel!
    @IBOutlet weak var estadoSwitch:   UISwitch!
    @IBOutlet weak var editarButton:   UIButton!
    @IBOutlet weak var eliminarButton: UIButton!
    
    var cliente: Cliente?
    var viewModel = ClienteViewModel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        cargarDatos()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = AppColors.background
        title = "Detalle Cliente"
        navigationController?.navigationBar.tintColor = AppColors.accent

        let historialBtn = UIBarButtonItem(title: "Compras", style: .plain, target: self, action: #selector(verHistorial))
        historialBtn.tintColor = AppColors.accent
        navigationItem.rightBarButtonItem = historialBtn

        view.addCard(frame: CGRect(x: 16, y: 123, width: view.frame.width - 32, height: 450))

        nombreLabel.font          = .systemFont(ofSize: 22, weight: .bold)
        nombreLabel.textColor     = AppColors.textPrimary
        nombreLabel.numberOfLines = 0
        
        dniLabel.font      = .systemFont(ofSize: 14)
        dniLabel.textColor = AppColors.textSecondary
        
        telefonoLabel.font      = .systemFont(ofSize: 14)
        telefonoLabel.textColor = AppColors.textSecondary
        
        correoLabel.font      = .systemFont(ofSize: 14)
        correoLabel.textColor = AppColors.textSecondary
        
        direccionLabel.font          = .systemFont(ofSize: 14)
        direccionLabel.textColor     = AppColors.textSecondary
        direccionLabel.numberOfLines = 0
        
        estadoLabel.font      = .systemFont(ofSize: 14, weight: .semibold)
        estadoLabel.textColor = AppColors.success
        
        estadoSwitch.onTintColor = AppColors.primary
        
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
        guard let c = cliente else { return }
        nombreLabel.text    = "\(c.nombres ?? "") \(c.apellidos ?? "")"
        dniLabel.text       = "DNI: \(c.dni ?? "")"
        telefonoLabel.text  = "Tel: \(c.telefono ?? "")"
        correoLabel.text    = "Email: \(c.correo ?? "")"
        direccionLabel.text = "Dir: \(c.direccion ?? "")"
        estadoSwitch.isOn   = c.estado
        
        if c.estado {
            estadoLabel.text      = "Activo"
            estadoLabel.textColor = AppColors.success
        } else {
            estadoLabel.text      = "Inactivo"
            estadoLabel.textColor = AppColors.danger
        }
    }
    
    // MARK: - Actions
    @IBAction func estadoSwitchChanged(_ sender: UISwitch) {
        guard let c = cliente else { return }
        _ = viewModel.actualizar(
            c,
            dni:       c.dni       ?? "",
            nombres:   c.nombres   ?? "",
            apellidos: c.apellidos ?? "",
            telefono:  c.telefono  ?? "",
            correo:    c.correo    ?? "",
            direccion: c.direccion ?? "",
            estado:    sender.isOn
        )
        estadoLabel.text      = sender.isOn ? "Activo" : "Inactivo"
        estadoLabel.textColor = sender.isOn ? AppColors.success : AppColors.danger
    }
    
    @IBAction func editarTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "goToClienteForm", sender: nil)
    }
    
    @IBAction func eliminarTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Eliminar", message: "¿Eliminar este cliente?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { _ in
            if let c = self.cliente {
                self.viewModel.eliminar(c)
                self.navigationController?.popViewController(animated: true)
            }
        })
        present(alert, animated: true)
    }
    
    @objc private func verHistorial() {
        guard let c = cliente else { return }
        let listVC = VentasListViewController()
        listVC.filterClienteId = c.idCliente
        navigationController?.pushViewController(listVC, animated: true)
    }

    // MARK: - Prepare Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToClienteForm" {
            let vc = segue.destination as! ClienteFormViewController
            vc.cliente   = cliente
            vc.viewModel = viewModel
        }
    }
}

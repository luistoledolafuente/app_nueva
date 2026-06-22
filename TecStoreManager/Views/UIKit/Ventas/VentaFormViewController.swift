import UIKit

class VentaFormViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var clienteField:   UITextField!
    @IBOutlet weak var productoField:  UITextField!
    @IBOutlet weak var cantidadField:  UITextField!
    @IBOutlet weak var precioLabel:    UILabel!
    @IBOutlet weak var subtotalLabel:  UILabel!
    @IBOutlet weak var igvLabel:       UILabel!
    @IBOutlet weak var totalLabel:     UILabel!
    @IBOutlet weak var errorLabel:     UILabel!
    @IBOutlet weak var registrarButton: UIButton!
    @IBOutlet weak var cancelarButton:  UIButton!
    
    var viewModel = VentaViewModel()
    
    private let clienteRepo  = ClienteRepository()
    private let productoRepo = ProductoRepository()
    
    private var clientes:  [Cliente]  = []
    private var productos: [Producto] = []
    private var clienteSeleccionado:  Cliente?
    private var productoSeleccionado: Producto?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        cargarDatos()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = AppColors.background
        title = "Nueva Venta"
        navigationController?.navigationBar.tintColor = AppColors.accent

        view.addCard(frame: CGRect(x: 16, y: 110, width: view.frame.width - 32, height: 250))
        view.addCard(frame: CGRect(x: 16, y: 350, width: view.frame.width - 32, height: 300))

        setupTextField(clienteField,  placeholder: "Seleccionar cliente")
        setupTextField(productoField, placeholder: "Seleccionar producto")
        setupTextField(cantidadField, placeholder: "0", keyboardType: .numberPad)
        
        clienteField.addTarget(self, action: #selector(clienteFieldTapped), for: .editingDidBegin)
        productoField.addTarget(self, action: #selector(productoFieldTapped), for: .editingDidBegin)
        cantidadField.addTarget(self, action: #selector(cantidadChanged), for: .editingChanged)
        
        precioLabel.text    = "S/ 0.00"
        precioLabel.font    = .systemFont(ofSize: 15, weight: .semibold)
        precioLabel.textColor = AppColors.accent
        
        subtotalLabel.text      = "S/ 0.00"
        subtotalLabel.font      = .systemFont(ofSize: 15, weight: .semibold)
        subtotalLabel.textColor = AppColors.textPrimary
        
        igvLabel.text      = "S/ 0.00"
        igvLabel.font      = .systemFont(ofSize: 15, weight: .semibold)
        igvLabel.textColor = AppColors.warning
        
        totalLabel.text      = "S/ 0.00"
        totalLabel.font      = .systemFont(ofSize: 20, weight: .bold)
        totalLabel.textColor = AppColors.success
        
        errorLabel.text          = ""
        errorLabel.textColor     = AppColors.danger
        errorLabel.font          = .systemFont(ofSize: 13)
        errorLabel.numberOfLines = 0
        
        registrarButton.setTitle("Registrar Venta", for: .normal)
        registrarButton.backgroundColor    = AppColors.primary
        registrarButton.setTitleColor(.white, for: .normal)
        registrarButton.titleLabel?.font   = .systemFont(ofSize: 16, weight: .semibold)
        registrarButton.layer.cornerRadius = 12
        
        cancelarButton.setTitle("Cancelar", for: .normal)
        cancelarButton.setTitleColor(AppColors.danger, for: .normal)
        cancelarButton.titleLabel?.font = .systemFont(ofSize: 15)
    }
    
    private func setupTextField(_ field: UITextField, placeholder: String, keyboardType: UIKeyboardType = .default) {
        field.placeholder           = placeholder
        field.keyboardType          = keyboardType
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
    
    private func cargarDatos() {
        clientes  = clienteRepo.obtenerTodos()
        productos = productoRepo.obtenerTodos()
    }
    
    // MARK: - Calcular totales
    private func calcularTotales() {
        guard let producto = productoSeleccionado,
              let cantidadStr = cantidadField.text,
              let cantidad = Double(cantidadStr) else {
            precioLabel.text   = "S/ 0.00"
            subtotalLabel.text = "S/ 0.00"
            igvLabel.text      = "S/ 0.00"
            totalLabel.text    = "S/ 0.00"
            return
        }
        
        let precio   = producto.precio
        let subtotal = cantidad * precio
        let igv      = subtotal * AppConstants.igvRate
        let total    = subtotal + igv
        
        precioLabel.text   = "S/ \(String(format: "%.2f", precio))"
        subtotalLabel.text = "S/ \(String(format: "%.2f", subtotal))"
        igvLabel.text      = "S/ \(String(format: "%.2f", igv))"
        totalLabel.text    = "S/ \(String(format: "%.2f", total))"
    }
    
    // MARK: - Pickers
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
    
    @objc private func productoFieldTapped() {
        productoField.resignFirstResponder()
        let alert = UIAlertController(title: "Seleccionar Producto", message: nil, preferredStyle: .actionSheet)
        for producto in productos {
            alert.addAction(UIAlertAction(title: "\(producto.nombre ?? "") - Stock: \(producto.stock)", style: .default) { _ in
                self.productoSeleccionado = producto
                self.productoField.text   = producto.nombre
                self.calcularTotales()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func cantidadChanged() {
        calcularTotales()
    }
    
    // MARK: - Actions
    @IBAction func registrarTapped(_ sender: UIButton) {
        guard let cliente  = clienteSeleccionado,
              let producto = productoSeleccionado else {
            errorLabel.text = "Selecciona cliente y producto"
            return
        }
        
        let cantidad = cantidadField.text ?? ""
        
        if viewModel.crear(cantidadStr: cantidad, cliente: cliente, producto: producto) {
            navigationController?.popViewController(animated: true)
        } else {
            errorLabel.text = viewModel.errorMessage
        }
    }
    
    @IBAction func cancelarTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

import UIKit
import SwiftUI

class ProductoFormViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var codigoField:    UITextField!
    @IBOutlet weak var nombreField:    UITextField!
    @IBOutlet weak var categoriaField: UITextField!
    @IBOutlet weak var precioField:    UITextField!
    @IBOutlet weak var stockField:     UITextField!
    @IBOutlet weak var errorLabel:     UILabel!
    @IBOutlet weak var guardarButton:  UIButton!
    @IBOutlet weak var cancelarButton: UIButton!
    
    var producto: Producto?
    var viewModel = ProductoViewModel()

    let categorias = ["Electronica", "Ropa", "Alimentos", "Hogar", "Deportes", "Otros"]
    private let categoriaPicker = UIPickerView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        cargarDatos()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = AppColors.background
        title = producto == nil ? "Nuevo Producto" : "Editar Producto"
        navigationController?.navigationBar.tintColor = AppColors.accent
        
        setupTextField(codigoField,    placeholder: "Ej: PROD001")
        setupTextField(nombreField,    placeholder: "Nombre del producto")
        setupTextField(categoriaField, placeholder: "Selecciona una categoría")
        setupTextField(precioField,    placeholder: "0.00", keyboardType: .decimalPad)
        setupTextField(stockField,     placeholder: "0",    keyboardType: .numberPad)

        setupCategoriaPicker()

        errorLabel.text          = ""
        errorLabel.textColor     = AppColors.danger
        errorLabel.font          = .systemFont(ofSize: 13)
        errorLabel.numberOfLines = 0
        
        guardarButton.setTitle("Guardar", for: .normal)
        guardarButton.backgroundColor    = AppColors.primary
        guardarButton.setTitleColor(.white, for: .normal)
        guardarButton.titleLabel?.font   = .systemFont(ofSize: 16, weight: .semibold)
        guardarButton.layer.cornerRadius = 12
        
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
        guard let p = producto else { return }
        codigoField.text    = p.codigo
        nombreField.text    = p.nombre
        categoriaField.text = p.categoria
        precioField.text    = String(p.precio)
        stockField.text     = String(p.stock)

        if let categoria = p.categoria, let index = categorias.firstIndex(of: categoria) {
            categoriaPicker.selectRow(index, inComponent: 0, animated: false)
        }
    }

    // MARK: - Picker de categoría
    private func setupCategoriaPicker() {
        categoriaPicker.delegate   = self
        categoriaPicker.dataSource = self

        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44))
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Listo", style: .done, target: self, action: #selector(categoriaListo))
        ]

        categoriaField.inputView          = categoriaPicker
        categoriaField.inputAccessoryView = toolbar

        if categoriaField.text?.isEmpty ?? true {
            categoriaField.text = categorias[0]
        }
    }

    @objc private func categoriaListo() {
        categoriaField.text = categorias[categoriaPicker.selectedRow(inComponent: 0)]
        categoriaField.resignFirstResponder()
    }
    
    // MARK: - Actions
    @IBAction func guardarTapped(_ sender: UIButton) {
        let codigo    = codigoField.text    ?? ""
        let nombre    = nombreField.text    ?? ""
        let categoria = categoriaField.text ?? ""
        let precio    = precioField.text    ?? ""
        let stock     = stockField.text     ?? ""
        
        var exito: Bool
        if let p = producto {
            exito = viewModel.actualizar(p, codigo: codigo, nombre: nombre, categoria: categoria, precioStr: precio, stockStr: stock)
        } else {
            exito = viewModel.crear(codigo: codigo, nombre: nombre, categoria: categoria, precioStr: precio, stockStr: stock)
        }
        
        if exito {
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

// MARK: - UIPickerViewDelegate, UIPickerViewDataSource
extension ProductoFormViewController: UIPickerViewDelegate, UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categorias.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categorias[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        categoriaField.text = categorias[row]
    }
}

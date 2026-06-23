import UIKit

class ClienteFormViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var dniField:       UITextField!
    @IBOutlet weak var nombresField:   UITextField!
    @IBOutlet weak var apellidosField: UITextField!
    @IBOutlet weak var telefonoField:  UITextField!
    @IBOutlet weak var correoField:    UITextField!
    @IBOutlet weak var direccionField: UITextField!
    @IBOutlet weak var errorLabel:     UILabel!
    @IBOutlet weak var guardarButton:  UIButton!
    @IBOutlet weak var cancelarButton: UIButton!

    var cliente: Cliente?
    var viewModel = ClienteViewModel()

    private var isConsultandoDNI = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        cargarDatos()
        setupDNIListener()
    }

    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = AppColors.background
        title = cliente == nil ? "Nuevo Cliente" : "Editar Cliente"
        navigationController?.navigationBar.tintColor = AppColors.primary

        setupTextField(dniField,       placeholder: "12345678",           keyboardType: .numberPad)
        setupTextField(nombresField,   placeholder: "Nombres del cliente")
        setupTextField(apellidosField, placeholder: "Apellidos del cliente")
        setupTextField(telefonoField,  placeholder: "987654321",           keyboardType: .phonePad)
        setupTextField(correoField,    placeholder: "correo@ejemplo.com",  keyboardType: .emailAddress)
        setupTextField(direccionField, placeholder: "Dirección del cliente")

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
        guard let c = cliente else { return }
        dniField.text       = c.dni
        nombresField.text   = c.nombres
        apellidosField.text = c.apellidos
        telefonoField.text  = c.telefono
        correoField.text    = c.correo
        direccionField.text = c.direccion
    }

    // MARK: - RENIEC Auto-completar
    private func setupDNIListener() {
        dniField.addTarget(self, action: #selector(dniDidChange), for: .editingChanged)
    }

    @objc private func dniDidChange() {
        guard cliente == nil else { return }
        let dni = dniField.text ?? ""
        if dni.count == 8 {
            consultarDNI(dni)
        }
    }

    private func consultarDNI(_ dni: String) {
        guard !isConsultandoDNI else { return }
        isConsultandoDNI = true
        dniField.isEnabled = false

        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = AppColors.primary
        dniField.rightView = activityIndicator
        dniField.rightViewMode = .always
        activityIndicator.startAnimating()

        Task {
            do {
                let data = try await ReniecService.shared.consultarDNI(dni)
                await MainActor.run {
                    nombresField.text   = data.nombres.capitalized
                    apellidosField.text = "\(data.apellidoPaterno.capitalized) \(data.apellidoMaterno.capitalized)".trimmingCharacters(in: .whitespaces)
                    let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                    checkmark.tintColor = AppColors.success
                    checkmark.sizeToFit()
                    dniField.rightView = checkmark
                    dniField.rightViewMode = .always
                    errorLabel.text = ""
                }
            } catch {
                await MainActor.run {
                    errorLabel.text = error.localizedDescription
                    dniField.rightView = nil
                }
            }
            await MainActor.run {
                dniField.isEnabled = true
                isConsultandoDNI = false
            }
        }
    }

    // MARK: - Actions
    @IBAction func guardarTapped(_ sender: UIButton) {
        let dni       = dniField.text       ?? ""
        let nombres   = nombresField.text   ?? ""
        let apellidos = apellidosField.text ?? ""
        let telefono  = telefonoField.text  ?? ""
        let correo    = correoField.text    ?? ""
        let direccion = direccionField.text ?? ""

        var exito: Bool
        if let c = cliente {
            exito = viewModel.actualizar(
                c,
                dni: dni,
                nombres: nombres,
                apellidos: apellidos,
                telefono: telefono,
                correo: correo,
                direccion: direccion,
                estado: c.estado
            )
        } else {
            exito = viewModel.crear(
                dni: dni,
                nombres: nombres,
                apellidos: apellidos,
                telefono: telefono,
                correo: correo,
                direccion: direccion
            )
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

import UIKit

class RegisterViewController: UIViewController {

    // MARK: - IBOutlets (storyboard — no tocar, mantener nombres)
    @IBOutlet weak var nombreField:    UITextField!
    @IBOutlet weak var usuarioField:   UITextField! // usado como email
    var emailField: UITextField { usuarioField }
    @IBOutlet weak var passwordField:  UITextField!
    @IBOutlet weak var confirmField:   UITextField!
    @IBOutlet weak var errorLabel:     UILabel!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var backButton:     UIButton!

    private let authViewModel = AuthViewModel()

    // Vistas y capas programáticas
    private let gradientLayer    = CAGradientLayer()
    private var btnGradientLayer = CAGradientLayer()
    private var circleTop        = UIView()
    private var circleBottom     = UIView()
    private var logoContainer    = UIView()
    private var cardView         = UIView()
    private var cardTitleLabel   = UILabel()
    private var cardSubtitleLabel = UILabel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        hideStoryboardDecorations()
        buildBackground()
        buildDecorativeCircles()
        buildLogoView()
        buildCard()
        buildCardLabels()
        styleFields()
        styleRegisterButton()
        styleBackButton()
        styleErrorLabel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let w = view.bounds.width
        let h = view.bounds.height

        gradientLayer.frame = view.bounds

        circleTop.frame    = CGRect(x: w - 100, y: -100, width: 260, height: 260)
        circleBottom.frame = CGRect(x: -80, y: h - 180, width: 230, height: 230)
        circleTop.layer.cornerRadius    = 130
        circleBottom.layer.cornerRadius = 115

        let hPad: CGFloat   = 18
        let cardTop: CGFloat = nombreField.frame.minY - 76
        let cardBot: CGFloat = backButton.frame.maxY + 22
        cardView.frame        = CGRect(x: hPad, y: cardTop,
                                       width: w - hPad * 2,
                                       height: cardBot - cardTop)
        cardView.layer.cornerRadius = 26

        cardTitleLabel.frame    = CGRect(x: hPad + 20, y: cardTop + 22,
                                          width: w - (hPad + 20) * 2, height: 28)
        cardSubtitleLabel.frame = CGRect(x: hPad + 20, y: cardTop + 52,
                                          width: w - (hPad + 20) * 2, height: 18)

        let logoSize: CGFloat = 84
        let logoY = max(cardTop - logoSize - 20, view.safeAreaInsets.top + 12)
        logoContainer.frame          = CGRect(x: (w - logoSize) / 2, y: logoY,
                                              width: logoSize, height: logoSize)
        logoContainer.layer.cornerRadius = logoSize / 2

        btnGradientLayer.frame        = registerButton.bounds
        btnGradientLayer.cornerRadius = registerButton.layer.cornerRadius

        attachIcon("person.text.rectangle", to: nombreField)
        attachIcon("envelope.fill",          to: emailField)
        attachIcon("lock.fill",              to: passwordField)
        attachIcon("lock.shield.fill",       to: confirmField)
    }

    // MARK: - Ocultar elementos del storyboard sin outlet
    private func hideStoryboardDecorations() {
        let outlets: [UIView?] = [nombreField, emailField, passwordField,
                                   confirmField, errorLabel, registerButton, backButton]
        let keep = Set(outlets.compactMap { $0 })
        view.subviews.forEach { if !keep.contains($0) { $0.isHidden = true } }
    }

    // MARK: - Fondo gradiente
    private func buildBackground() {
        gradientLayer.colors = [
            UIColor(hex: "#0F766E").cgColor,
            UIColor(hex: "#0D9488").cgColor,
            UIColor(hex: "#0891B2").cgColor
        ]
        gradientLayer.locations   = [0, 0.55, 1]
        gradientLayer.startPoint  = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint    = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    // MARK: - Círculos decorativos
    private func buildDecorativeCircles() {
        circleTop.backgroundColor = UIColor.white.withAlphaComponent(0.07)
        view.insertSubview(circleTop, at: 1)

        circleBottom.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        view.insertSubview(circleBottom, at: 1)
    }

    // MARK: - Logo
    private func buildLogoView() {
        logoContainer.backgroundColor     = UIColor.white.withAlphaComponent(0.20)
        logoContainer.layer.shadowColor   = UIColor.black.cgColor
        logoContainer.layer.shadowOpacity = 0.22
        logoContainer.layer.shadowRadius  = 20
        logoContainer.layer.shadowOffset  = CGSize(width: 0, height: 8)

        let inner = UIView()
        inner.backgroundColor    = UIColor.white.withAlphaComponent(0.14)
        inner.layer.cornerRadius = 30
        inner.translatesAutoresizingMaskIntoConstraints = false
        logoContainer.addSubview(inner)

        let config  = UIImage.SymbolConfiguration(pointSize: 32, weight: .bold)
        let imgView = UIImageView(image: UIImage(systemName: "person.badge.plus",
                                                  withConfiguration: config))
        imgView.tintColor    = .white
        imgView.contentMode  = .scaleAspectFit
        imgView.translatesAutoresizingMaskIntoConstraints = false
        logoContainer.addSubview(imgView)

        NSLayoutConstraint.activate([
            inner.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
            inner.centerYAnchor.constraint(equalTo: logoContainer.centerYAnchor),
            inner.widthAnchor.constraint(equalToConstant: 60),
            inner.heightAnchor.constraint(equalToConstant: 60),
            imgView.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
            imgView.centerYAnchor.constraint(equalTo: logoContainer.centerYAnchor),
            imgView.widthAnchor.constraint(equalToConstant: 36),
            imgView.heightAnchor.constraint(equalToConstant: 36)
        ])

        view.addSubview(logoContainer)
    }

    // MARK: - Card blanca
    private func buildCard() {
        cardView.backgroundColor     = .white
        cardView.layer.shadowColor   = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.16
        cardView.layer.shadowRadius  = 28
        cardView.layer.shadowOffset  = CGSize(width: 0, height: 12)
        view.insertSubview(cardView, belowSubview: nombreField)
    }

    // MARK: - Títulos del card
    private func buildCardLabels() {
        cardTitleLabel.text      = "Crear cuenta"
        cardTitleLabel.font      = .systemFont(ofSize: 22, weight: .bold)
        cardTitleLabel.textColor = .black
        view.addSubview(cardTitleLabel)

        cardSubtitleLabel.text      = "Completa tus datos para registrarte"
        cardSubtitleLabel.font      = .systemFont(ofSize: 13)
        cardSubtitleLabel.textColor = UIColor(hex: "#475569")
        view.addSubview(cardSubtitleLabel)
    }

    // MARK: - Estilo de campos
    private func styleFields() {
        let fields: [UITextField?] = [nombreField, emailField, passwordField, confirmField]
        for field in fields {
            guard let f = field else { continue }
            f.textColor           = UIColor(hex: "#0F172A")
            f.backgroundColor     = UIColor(hex: "#F0FDF4")
            f.font                = .systemFont(ofSize: 15)
            f.layer.cornerRadius  = 13
            f.layer.borderWidth   = 1
            f.layer.borderColor   = UIColor(hex: "#0D9488").withAlphaComponent(0.18).cgColor
            f.layer.masksToBounds = true
        }
        passwordField.isSecureTextEntry = true
        confirmField.isSecureTextEntry  = true

        nombreField.attributedPlaceholder   = placeholder("Nombre completo")
        emailField.attributedPlaceholder    = placeholder("Correo electrónico")
        passwordField.attributedPlaceholder = placeholder("Contraseña")
        confirmField.attributedPlaceholder  = placeholder("Confirmar contraseña")
        emailField.keyboardType = .emailAddress
    }

    private func attachIcon(_ systemName: String, to field: UITextField) {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: field.frame.height))
        let config    = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let img       = UIImageView(image: UIImage(systemName: systemName,
                                                    withConfiguration: config))
        img.tintColor   = UIColor(hex: "#475569")
        img.contentMode = .scaleAspectFit
        let iconH: CGFloat = 18
        img.frame = CGRect(x: 13, y: (container.frame.height - iconH) / 2,
                            width: 18, height: iconH)
        container.addSubview(img)
        field.leftView     = container
        field.leftViewMode = .always
    }

    private func placeholder(_ text: String) -> NSAttributedString {
        NSAttributedString(string: text,
                           attributes: [.foregroundColor: UIColor(hex: "#475569")])
    }

    // MARK: - Botón crear cuenta
    private func styleRegisterButton() {
        registerButton.setTitle("Crear cuenta", for: .normal)
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.titleLabel?.font    = .systemFont(ofSize: 16, weight: .semibold)
        registerButton.layer.cornerRadius  = 14
        registerButton.layer.masksToBounds = false

        btnGradientLayer.colors     = [UIColor(hex: "#0D9488").cgColor,
                                        UIColor(hex: "#0F766E").cgColor]
        btnGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        btnGradientLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        registerButton.layer.insertSublayer(btnGradientLayer, at: 0)

        registerButton.layer.shadowColor   = UIColor(hex: "#0D9488").cgColor
        registerButton.layer.shadowOpacity = 0.40
        registerButton.layer.shadowRadius  = 14
        registerButton.layer.shadowOffset  = CGSize(width: 0, height: 6)
    }

    // MARK: - Botón volver (link)
    private func styleBackButton() {
        let attr = NSMutableAttributedString(
            string: "¿Ya tienes cuenta? ",
            attributes: [.foregroundColor: UIColor(hex: "#475569"),
                         .font: UIFont.systemFont(ofSize: 14)]
        )
        attr.append(NSAttributedString(
            string: "Inicia sesión",
            attributes: [.foregroundColor: UIColor(hex: "#0D9488"),
                         .font: UIFont.systemFont(ofSize: 14, weight: .bold)]
        ))
        backButton.setAttributedTitle(attr, for: .normal)
        backButton.backgroundColor = .clear
    }

    // MARK: - Error label
    private func styleErrorLabel() {
        errorLabel.text          = ""
        errorLabel.textColor     = UIColor(hex: "#EF4444")
        errorLabel.font          = .systemFont(ofSize: 13, weight: .medium)
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
    }

    // MARK: - Actions
    @IBAction func registerTapped(_ sender: UIButton) {
        animateButtonPress(sender)

        let nombre  = nombreField.text   ?? ""
        let email   = emailField.text    ?? ""
        let pass    = passwordField.text ?? ""
        let confirm = confirmField.text  ?? ""

        guard pass == confirm else {
            errorLabel.text = "Las contraseñas no coinciden"
            shakeView(errorLabel)
            return
        }

        guard !nombre.isEmpty, !email.isEmpty else {
            errorLabel.text = "Todos los campos son obligatorios"
            shakeView(errorLabel)
            return
        }

        registerButton.isEnabled = false
        registerButton.setTitle("Creando cuenta...", for: .normal)
        Task {
            let exito = await authViewModel.register(
                email: email,
                password: pass,
                nombreCompleto: nombre
            )
            registerButton.isEnabled = true
            registerButton.setTitle("Crear cuenta", for: .normal)
            if exito {
                let alert = UIAlertController(
                    title: "¡Cuenta creada!",
                    message: "Tu cuenta fue registrada exitosamente. Ya puedes iniciar sesión.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Iniciar sesión", style: .default) { _ in
                    self.navigationController?.popViewController(animated: true)
                })
                present(alert, animated: true)
            } else {
                errorLabel.text = authViewModel.errorMessage
                shakeView(errorLabel)
            }
        }
    }

    @IBAction func backTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Animaciones
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logoContainer.alpha      = 0
        logoContainer.transform  = CGAffineTransform(scaleX: 0.55, y: 0.55)
        cardView.alpha           = 0
        cardView.transform       = CGAffineTransform(translationX: 0, y: 50)
        cardTitleLabel.alpha     = 0
        cardSubtitleLabel.alpha  = 0
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.65, delay: 0,
                       usingSpringWithDamping: 0.68, initialSpringVelocity: 0.5) {
            self.logoContainer.alpha     = 1
            self.logoContainer.transform = .identity
        }
        UIView.animate(withDuration: 0.6, delay: 0.15,
                       usingSpringWithDamping: 0.80, initialSpringVelocity: 0.5) {
            self.cardView.alpha     = 1
            self.cardView.transform = .identity
        }
        UIView.animate(withDuration: 0.4, delay: 0.30) {
            self.cardTitleLabel.alpha    = 1
            self.cardSubtitleLabel.alpha = 1
        }
    }

    private func animateButtonPress(_ button: UIButton) {
        UIView.animate(withDuration: 0.1, animations: {
            button.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }) { _ in
            UIView.animate(withDuration: 0.15, delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 0.8,
                           options: [],
                           animations: { button.transform = .identity },
                           completion: nil)
        }
    }

    private func shakeView(_ view: UIView) {
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.values   = [-10, 10, -8, 8, -5, 5, 0]
        anim.duration = 0.45
        view.layer.add(anim, forKey: "shake")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

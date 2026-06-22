import UIKit

class LoginViewController: UIViewController {

    // MARK: - IBOutlets (storyboard — no tocar)
    @IBOutlet weak var usuarioField:   UITextField!
    @IBOutlet weak var passwordField:  UITextField!
    @IBOutlet weak var errorLabel:     UILabel!
    @IBOutlet weak var loginButton:    UIButton!
    @IBOutlet weak var registerButton: UIButton!

    private let authViewModel = AuthViewModel()

    // Vistas y capas agregadas programáticamente
    private let gradientLayer     = CAGradientLayer()
    private var btnGradientLayer  = CAGradientLayer()
    private var circleTop         = UIView()
    private var circleBottom      = UIView()
    private var logoContainer     = UIView()
    private var cardView          = UIView()
    private var cardTitleLabel    = UILabel()
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
        styleLoginButton()
        styleRegisterButton()
        styleErrorLabel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let w = view.bounds.width
        let h = view.bounds.height

        // Fondo gradiente
        gradientLayer.frame = view.bounds

        // Círculos decorativos
        circleTop.frame    = CGRect(x: w - 110, y: -90, width: 260, height: 260)
        circleBottom.frame = CGRect(x: -90, y: h - 160, width: 240, height: 240)
        circleTop.layer.cornerRadius    = 130
        circleBottom.layer.cornerRadius = 120

        // Card: desde arriba de los campos hasta abajo del botón register
        let hPad: CGFloat   = 18
        let cardTop: CGFloat = usuarioField.frame.minY - 76   // espacio para titulo
        let cardBot: CGFloat = registerButton.frame.maxY + 22
        cardView.frame  = CGRect(x: hPad, y: cardTop,
                                 width: w - hPad * 2,
                                 height: cardBot - cardTop)
        cardView.layer.cornerRadius = 26

        // Título y subtítulo dentro del card
        cardTitleLabel.frame    = CGRect(x: hPad + 20, y: cardTop + 22,
                                         width: w - (hPad + 20) * 2, height: 28)
        cardSubtitleLabel.frame = CGRect(x: hPad + 20, y: cardTop + 52,
                                         width: w - (hPad + 20) * 2, height: 18)

        // Logo encima del card
        let logoSize: CGFloat = 88
        let logoY = max(cardTop - logoSize - 22, view.safeAreaInsets.top + 14)
        logoContainer.frame          = CGRect(x: (w - logoSize) / 2, y: logoY,
                                              width: logoSize, height: logoSize)
        logoContainer.layer.cornerRadius = logoSize / 2

        // Botón con gradiente
        btnGradientLayer.frame        = loginButton.bounds
        btnGradientLayer.cornerRadius = loginButton.layer.cornerRadius

        // Iconos en los campos (necesitan el frame final)
        attachIcon("person.fill",  to: usuarioField)
        attachIcon("lock.fill",    to: passwordField)
    }

    // MARK: - Ocultar elementos del storyboard sin outlet
    private func hideStoryboardDecorations() {
        let outlets: [UIView?] = [usuarioField, passwordField,
                                   errorLabel, loginButton, registerButton]
        let keep = Set(outlets.compactMap { $0 })
        view.subviews.forEach { if !keep.contains($0) { $0.isHidden = true } }
    }

    // MARK: - Fondo gradiente
    private func buildBackground() {
        gradientLayer.colors = [
            UIColor(hex: "#3730A3").cgColor,
            UIColor(hex: "#4F46E5").cgColor,
            UIColor(hex: "#7C3AED").cgColor
        ]
        gradientLayer.locations   = [0, 0.5, 1]
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

        // Círculo interior
        let inner = UIView()
        inner.backgroundColor    = UIColor.white.withAlphaComponent(0.14)
        inner.layer.cornerRadius = 32
        inner.translatesAutoresizingMaskIntoConstraints = false
        logoContainer.addSubview(inner)

        // Ícono SF Symbol
        let config = UIImage.SymbolConfiguration(pointSize: 34, weight: .bold)
        let imgView = UIImageView(image: UIImage(systemName: "cart.fill.badge.plus",
                                                  withConfiguration: config))
        imgView.tintColor    = .white
        imgView.contentMode  = .scaleAspectFit
        imgView.translatesAutoresizingMaskIntoConstraints = false
        logoContainer.addSubview(imgView)

        NSLayoutConstraint.activate([
            inner.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
            inner.centerYAnchor.constraint(equalTo: logoContainer.centerYAnchor),
            inner.widthAnchor.constraint(equalToConstant: 64),
            inner.heightAnchor.constraint(equalToConstant: 64),
            imgView.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
            imgView.centerYAnchor.constraint(equalTo: logoContainer.centerYAnchor),
            imgView.widthAnchor.constraint(equalToConstant: 38),
            imgView.heightAnchor.constraint(equalToConstant: 38)
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
        view.insertSubview(cardView, belowSubview: usuarioField)
    }

    // MARK: - Título y subtítulo del card
    private func buildCardLabels() {
        cardTitleLabel.text      = "Iniciar sesión"
        cardTitleLabel.font      = .systemFont(ofSize: 22, weight: .bold)
        cardTitleLabel.textColor = UIColor(hex: "#1E2024")
        view.addSubview(cardTitleLabel)

        cardSubtitleLabel.text      = "Bienvenido de vuelta"
        cardSubtitleLabel.font      = .systemFont(ofSize: 13)
        cardSubtitleLabel.textColor = UIColor(hex: "#64748B")
        view.addSubview(cardSubtitleLabel)
    }

    // MARK: - Estilo de campos
    private func styleFields() {
        for field in [usuarioField, passwordField] {
            guard let f = field else { continue }
            f.textColor           = UIColor(hex: "#1E2024")
            f.backgroundColor     = UIColor(hex: "#F8FAFC")
            f.font                = .systemFont(ofSize: 15)
            f.layer.cornerRadius  = 13
            f.layer.borderWidth   = 1
            f.layer.borderColor   = UIColor(hex: "#4F46E5").withAlphaComponent(0.18).cgColor
            f.layer.masksToBounds = true
        }
        usuarioField.isSecureTextEntry  = false
        passwordField.isSecureTextEntry = true

        usuarioField.attributedPlaceholder = placeholder("Usuario")
        passwordField.attributedPlaceholder = placeholder("Contraseña")
    }

    private func attachIcon(_ systemName: String, to field: UITextField) {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: field.frame.height))
        let config    = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let img       = UIImageView(image: UIImage(systemName: systemName,
                                                    withConfiguration: config))
        img.tintColor   = UIColor(hex: "#64748B")
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
                           attributes: [.foregroundColor: UIColor(hex: "#64748B")])
    }

    // MARK: - Botón login
    private func styleLoginButton() {
        loginButton.setTitle("Ingresar", for: .normal)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font   = .systemFont(ofSize: 16, weight: .semibold)
        loginButton.layer.cornerRadius = 14
        loginButton.layer.masksToBounds = false

        btnGradientLayer.colors     = [UIColor(hex: "#4F46E5").cgColor,
                                        UIColor(hex: "#7C3AED").cgColor]
        btnGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        btnGradientLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        loginButton.layer.insertSublayer(btnGradientLayer, at: 0)

        loginButton.layer.shadowColor   = UIColor(hex: "#4F46E5").cgColor
        loginButton.layer.shadowOpacity = 0.45
        loginButton.layer.shadowRadius  = 14
        loginButton.layer.shadowOffset  = CGSize(width: 0, height: 6)
    }

    // MARK: - Botón register (link)
    private func styleRegisterButton() {
        let attr = NSMutableAttributedString(
            string: "¿No tienes cuenta? ",
            attributes: [.foregroundColor: UIColor(hex: "#64748B"),
                         .font: UIFont.systemFont(ofSize: 14)]
        )
        attr.append(NSAttributedString(
            string: "Regístrate",
            attributes: [.foregroundColor: UIColor(hex: "#4F46E5"),
                         .font: UIFont.systemFont(ofSize: 14, weight: .bold)]
        ))
        registerButton.setAttributedTitle(attr, for: .normal)
        registerButton.backgroundColor = .clear
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
    @IBAction func loginTapped(_ sender: UIButton) {
        animateButtonPress(sender)
        let user = usuarioField.text  ?? ""
        let pass = passwordField.text ?? ""
        if authViewModel.login(nombreUsuario: user, password: pass) {
            performSegue(withIdentifier: "goToMenu", sender: nil)
        } else {
            errorLabel.text = authViewModel.errorMessage
            shakeView(errorLabel)
        }
    }

    @IBAction func registerTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "goToRegister", sender: nil)
    }

    // MARK: - Animaciones
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logoContainer.alpha     = 0
        logoContainer.transform = CGAffineTransform(scaleX: 0.55, y: 0.55)
        cardView.alpha          = 0
        cardView.transform      = CGAffineTransform(translationX: 0, y: 50)
        cardTitleLabel.alpha    = 0
        cardSubtitleLabel.alpha = 0
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.65, delay: 0,
                       usingSpringWithDamping: 0.68, initialSpringVelocity: 0.5) {
            self.logoContainer.alpha     = 1
            self.logoContainer.transform = .identity
        }
        UIView.animate(withDuration: 0.6, delay: 0.18,
                       usingSpringWithDamping: 0.80, initialSpringVelocity: 0.5) {
            self.cardView.alpha     = 1
            self.cardView.transform = .identity
        }
        UIView.animate(withDuration: 0.4, delay: 0.32) {
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

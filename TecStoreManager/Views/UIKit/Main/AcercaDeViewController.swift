import UIKit

class AcercaDeViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var appNameLabel:   UILabel!
    @IBOutlet weak var versionLabel:   UILabel!
    @IBOutlet weak var techLabel:      UILabel!
    @IBOutlet weak var arquitectLabel: UILabel!
    @IBOutlet weak var docenteLabel:   UILabel!
    @IBOutlet weak var cursoLabel:     UILabel!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = AppColors.background
        title = "Acerca de"
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.tintColor = AppColors.accent

        view.addCard(frame: CGRect(x: 16, y: 235, width: view.frame.width - 32, height: 290))

        appNameLabel.text      = "TecStore Manager"
        appNameLabel.font      = .systemFont(ofSize: 28, weight: .bold)
        appNameLabel.textColor = AppColors.accent
        appNameLabel.textAlignment = .center
        appNameLabel.numberOfLines = 0

        versionLabel.text      = "Version 1.0.0"
        versionLabel.font      = .systemFont(ofSize: 14)
        versionLabel.textColor = AppColors.textSecondary
        versionLabel.textAlignment = .center

        techLabel.text      = "UIKit + SwiftUI + Core Data"
        techLabel.textColor = AppColors.textPrimary
        techLabel.font      = .systemFont(ofSize: 14, weight: .medium)

        arquitectLabel.text      = "MVVM + Repository Pattern"
        arquitectLabel.textColor = AppColors.textPrimary
        arquitectLabel.font      = .systemFont(ofSize: 14, weight: .medium)

        docenteLabel.text      = "Juan Leon"
        docenteLabel.textColor = AppColors.textPrimary
        docenteLabel.font      = .systemFont(ofSize: 14, weight: .medium)

        cursoLabel.text      = "Desarrollo iOS"
        cursoLabel.textColor = AppColors.textPrimary
        cursoLabel.font      = .systemFont(ofSize: 14, weight: .medium)

        addCaption(above: techLabel,      text: "Tecnologías")
        addCaption(above: arquitectLabel, text: "Arquitectura")
        addCaption(above: docenteLabel,   text: "Docente")
        addCaption(above: cursoLabel,     text: "Curso")
    }
}

import UIKit

class ConfiguracionViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var darkModeSwitch:   UISwitch!
    @IBOutlet weak var stockAlertSwitch: UISwitch!
    @IBOutlet weak var reminderSwitch:   UISwitch!
    @IBOutlet weak var igvLabel:         UILabel!
    @IBOutlet weak var monedaLabel:      UILabel!
    @IBOutlet weak var versionLabel:     UILabel!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = AppColors.background
        title = "Configuracion"
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.tintColor = AppColors.accent
        
        view.addCard(frame: CGRect(x: 16, y: 135, width: view.frame.width - 32, height: 200))
        view.addCard(frame: CGRect(x: 16, y: 350, width: view.frame.width - 32, height: 130))
        view.addCard(frame: CGRect(x: 16, y: 495, width: view.frame.width - 32, height: 120))

        darkModeSwitch.isOn    = true
        stockAlertSwitch.isOn  = true
        reminderSwitch.isOn    = false
        
        darkModeSwitch.onTintColor   = AppColors.primary
        stockAlertSwitch.onTintColor = AppColors.primary
        reminderSwitch.onTintColor   = AppColors.primary
        
        igvLabel.text      = "18%"
        igvLabel.textColor = AppColors.accent
        igvLabel.font      = .systemFont(ofSize: 15, weight: .semibold)
        
        monedaLabel.text      = "S/."
        monedaLabel.textColor = AppColors.accent
        monedaLabel.font      = .systemFont(ofSize: 15, weight: .semibold)
        
        versionLabel.text      = "1.0.0"
        versionLabel.textColor = AppColors.accent
        versionLabel.font      = .systemFont(ofSize: 15, weight: .semibold)
    }
    
    // MARK: - Actions
    @IBAction func darkModeSwitchChanged(_ sender: UISwitch) {
        print("Modo oscuro: \(sender.isOn)")
    }
    
    @IBAction func stockAlertSwitchChanged(_ sender: UISwitch) {
        print("Alertas stock: \(sender.isOn)")
    }
    
    @IBAction func reminderSwitchChanged(_ sender: UISwitch) {
        print("Recordatorios: \(sender.isOn)")
    }
}

import UIKit
import MapKit
import CoreLocation

class MapaViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var mapView:        MKMapView!
    @IBOutlet weak var latitudLabel:   UILabel!
    @IBOutlet weak var longitudLabel:  UILabel!
    @IBOutlet weak var referenciaField: UITextField!
    @IBOutlet weak var obtenerButton:  UIButton!
    @IBOutlet weak var guardarButton:  UIButton!
    @IBOutlet weak var errorLabel:     UILabel!
    
    private let viewModel = UbicacionViewModel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupObservers()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = AppColors.background
        title = "Mapa y Ubicacion"
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.tintColor = AppColors.accent
        
        mapView.layer.cornerRadius = 12
        mapView.showsUserLocation  = true

        view.addCard(frame: CGRect(x: 16, y: 320, width: view.frame.width - 32, height: 290))

        latitudLabel.text      = "Latitud: --"
        latitudLabel.font      = .systemFont(ofSize: 13)
        latitudLabel.textColor = AppColors.textSecondary
        
        longitudLabel.text      = "Longitud: --"
        longitudLabel.font      = .systemFont(ofSize: 13)
        longitudLabel.textColor = AppColors.textSecondary
        
        referenciaField.placeholder        = "Referencia (ej: Oficina principal)"
        referenciaField.backgroundColor    = AppColors.surface
        referenciaField.textColor          = AppColors.textPrimary
        referenciaField.layer.cornerRadius = 12
        referenciaField.layer.borderWidth  = 0.5
        referenciaField.layer.borderColor  = AppColors.primary.withAlphaComponent(0.3).cgColor
        referenciaField.leftView           = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        referenciaField.leftViewMode       = .always
        referenciaField.attributedPlaceholder = NSAttributedString(
            string: "Referencia (ej: Oficina principal)",
            attributes: [.foregroundColor: AppColors.textSecondary]
        )
        
        obtenerButton.setTitle("Obtener Mi Ubicacion", for: .normal)
        obtenerButton.backgroundColor    = AppColors.primary
        obtenerButton.setTitleColor(.white, for: .normal)
        obtenerButton.titleLabel?.font   = .systemFont(ofSize: 15, weight: .semibold)
        obtenerButton.layer.cornerRadius = 12
        
        guardarButton.setTitle("Guardar Ubicacion", for: .normal)
        guardarButton.backgroundColor    = AppColors.success
        guardarButton.setTitleColor(.white, for: .normal)
        guardarButton.titleLabel?.font   = .systemFont(ofSize: 15, weight: .semibold)
        guardarButton.layer.cornerRadius = 12
        guardarButton.isEnabled          = false
        guardarButton.alpha              = 0.5
        
        errorLabel.text          = ""
        errorLabel.textColor     = AppColors.danger
        errorLabel.font          = .systemFont(ofSize: 13)
        errorLabel.numberOfLines = 0
    }
    
    private func setupObservers() {
        cargarUbicacionesGuardadas()
    }
    
    private func cargarUbicacionesGuardadas() {
        mapView.removeAnnotations(mapView.annotations)
        for ubicacion in viewModel.ubicaciones {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(
                latitude:  ubicacion.latitud,
                longitude: ubicacion.longitud
            )
            annotation.title    = ubicacion.direccionReferencia
            annotation.subtitle = "Guardada"
            mapView.addAnnotation(annotation)
        }
    }
    
    private func actualizarMapa(lat: Double, lon: Double) {
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let region = MKCoordinateRegion(
            center: coordinate,
            span:   MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        mapView.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title      = "Tu ubicacion"
        mapView.addAnnotation(annotation)
        
        latitudLabel.text  = "Latitud: \(String(format: "%.6f", lat))"
        longitudLabel.text = "Longitud: \(String(format: "%.6f", lon))"
        
        guardarButton.isEnabled = true
        guardarButton.alpha     = 1.0
    }
    
    // MARK: - Actions
    @IBAction func obtenerTapped(_ sender: UIButton) {
        viewModel.solicitarPermiso()
        viewModel.obtenerUbicacion()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if self.viewModel.latitudActual != 0.0 {
                self.actualizarMapa(
                    lat: self.viewModel.latitudActual,
                    lon: self.viewModel.longitudActual
                )
                self.errorLabel.text = ""
            } else {
                self.errorLabel.text = self.viewModel.errorMessage.isEmpty ?
                    "No se pudo obtener la ubicacion" : self.viewModel.errorMessage
            }
        }
    }
    
    @IBAction func guardarTapped(_ sender: UIButton) {
        viewModel.direccionReferencia = referenciaField.text ?? ""
        
        if viewModel.guardarUbicacion() {
            let alert = UIAlertController(
                title:   "Ubicacion guardada",
                message: "La ubicacion fue guardada correctamente",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            referenciaField.text = ""
            cargarUbicacionesGuardadas()
        } else {
            errorLabel.text = viewModel.errorMessage
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

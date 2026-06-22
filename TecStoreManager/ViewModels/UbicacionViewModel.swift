import Foundation
import CoreLocation
import CoreData

class UbicacionViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var ubicaciones: [Ubicacion]      = []
    @Published var latitudActual: Double         = 0.0
    @Published var longitudActual: Double        = 0.0
    @Published var direccionReferencia: String   = ""
    @Published var errorMessage: String          = ""
    @Published var permisoConcedido: Bool        = false
    
    private let locationManager = CLLocationManager()
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.context) {
        self.context = context
        super.init()
        locationManager.delegate        = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        cargar()
    }
    
    // MARK: - Solicitar permiso
    func solicitarPermiso() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Obtener ubicacion
    func obtenerUbicacion() {
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        latitudActual  = location.coordinate.latitude
        longitudActual = location.coordinate.longitude
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Error obteniendo ubicación: \(error.localizedDescription)"
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            permisoConcedido = true
            obtenerUbicacion()
        case .denied, .restricted:
            permisoConcedido = false
            errorMessage     = "Permiso de ubicación denegado"
        default:
            break
        }
    }
    
    // MARK: - Guardar ubicacion
    func guardarUbicacion() -> Bool {
        guard latitudActual != 0.0, longitudActual != 0.0 else {
            errorMessage = "Primero obtén tu ubicación"
            return false
        }
        
        let ubicacion = Ubicacion(context: context)
        ubicacion.idUbicacion         = UUID()
        ubicacion.latitud             = latitudActual
        ubicacion.longitud            = longitudActual
        ubicacion.direccionReferencia = direccionReferencia
        ubicacion.fechaRegistro       = Date()
        
        PersistenceController.shared.save()
        cargar()
        errorMessage = ""
        return true
    }
    
    // MARK: - Cargar
    func cargar() {
        let request: NSFetchRequest<Ubicacion> = Ubicacion.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "fechaRegistro", ascending: false)]
        ubicaciones = (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Eliminar
    func eliminar(_ ubicacion: Ubicacion) {
        context.delete(ubicacion)
        PersistenceController.shared.save()
        cargar()
    }
}

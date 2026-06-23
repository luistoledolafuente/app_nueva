import Foundation

// MARK: - Modelo de respuesta RENIEC
struct ReniecSuccessResponse: Codable {
    let success: Bool
    let data:    ReniecData?
}

struct ReniecData: Codable {
    let numero:            String
    let nombreCompleto:    String
    let nombres:           String
    let apellidoPaterno:   String
    let apellidoMaterno:   String
    let codigoVerificacion: Int?

    enum CodingKeys: String, CodingKey {
        case numero
        case nombreCompleto    = "nombre_completo"
        case nombres
        case apellidoPaterno   = "apellido_paterno"
        case apellidoMaterno   = "apellido_materno"
        case codigoVerificacion = "codigo_verificacion"
    }
}

// MARK: - RENIEC API Service (apiperu.dev)
class ReniecService {

    static let shared = ReniecService()

    private let apiKey = "18413|bG4lef6vB5iJPSNMYEDXtnNagYf5sKnXYvJSTV6Fae56e7a0"
    private let baseURL = "https://apiperu.dev/api/dni"

    private init() {}

    func consultarDNI(_ dni: String) async throws -> ReniecData {
        guard dni.count == 8, dni.allSatisfy({ $0.isNumber }) else {
            throw ReniecError.invalidDNI
        }

        guard let url = URL(string: baseURL) else {
            throw ReniecError.invalidURL
        }

        let body: [String: String] = ["dni": dni]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReniecError.networkError
        }

        let raw = String(data: data, encoding: .utf8) ?? "nil"
        print("[RENIEC] Status: \(httpResponse.statusCode), Body: \(raw.prefix(500))")

        guard httpResponse.statusCode == 200 else {
            throw ReniecError.serverError(httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            let wrapper = try decoder.decode(ReniecSuccessResponse.self, from: data)
            if wrapper.success, let data = wrapper.data {
                return data
            }
            throw ReniecError.dniNotFound
        } catch let decodingError as DecodingError {
            print("[RENIEC] Decoding error: \(decodingError)")
            throw ReniecError.invalidResponse(raw: raw)
        }
    }
}

// MARK: - Errores
enum ReniecError: LocalizedError {
    case invalidDNI
    case invalidURL
    case networkError
    case dniNotFound
    case unauthorized
    case rateLimit
    case serverError(Int)
    case invalidResponse(raw: String)

    var errorDescription: String? {
        switch self {
        case .invalidDNI:
            return "DNI inválido (debe tener 8 dígitos)"
        case .invalidURL:
            return "Error de conexión con RENIEC"
        case .networkError:
            return "Error de red. Verifica tu conexión"
        case .dniNotFound:
            return "No se encontraron datos para este DNI"
        case .unauthorized:
            return "API Key inválida. Regístrate en https://apiperu.dev y actualiza el token en ReniecService"
        case .rateLimit:
            return "Límite de consultas diarias alcanzado"
        case .serverError(let code):
            return "Error del servidor RENIEC (código \(code)). Revisa la consola para ver la respuesta."
        case .invalidResponse(let raw):
            return "Respuesta inesperada del servidor. Revisa la consola para depurar. (raw: \(raw.prefix(100)))"
        }
    }
}

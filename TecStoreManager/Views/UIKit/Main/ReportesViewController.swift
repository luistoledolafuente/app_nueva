import UIKit

class ReportesViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var totalVentasLabel:     UILabel!
    @IBOutlet weak var montoTotalLabel:      UILabel!
    @IBOutlet weak var totalClientesLabel:   UILabel!
    @IBOutlet weak var totalProductosLabel:  UILabel!
    @IBOutlet weak var menorStockNombreLabel: UILabel!
    @IBOutlet weak var menorStockCantLabel:  UILabel!
    @IBOutlet weak var subtotalFiscalLabel:  UILabel!
    @IBOutlet weak var igvTotalLabel:        UILabel!
    @IBOutlet weak var totalFiscalLabel:     UILabel!
    
    private let ventaVM    = VentaViewModel()
    private let clienteVM  = ClienteViewModel()
    private let productoVM = ProductoViewModel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        cargarReportes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cargarReportes()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = AppColors.background
        title = "Reportes"
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.tintColor = AppColors.accent
        
        setupLabel(totalVentasLabel,    size: 28, weight: .bold,   color: AppColors.accent)
        setupLabel(montoTotalLabel,     size: 28, weight: .bold,   color: AppColors.success)
        setupLabel(totalClientesLabel,  size: 28, weight: .bold,   color: UIColor(hex: "#0891B2"))
        setupLabel(totalProductosLabel, size: 28, weight: .bold,   color: UIColor(hex: "#7C3AED"))
        setupLabel(menorStockNombreLabel, size: 15, weight: .semibold, color: AppColors.textPrimary)
        setupLabel(menorStockCantLabel,   size: 24, weight: .bold,     color: AppColors.danger)
        setupLabel(subtotalFiscalLabel,   size: 15, weight: .semibold, color: AppColors.textPrimary)
        setupLabel(igvTotalLabel,         size: 15, weight: .semibold, color: AppColors.warning)
        setupLabel(totalFiscalLabel,      size: 20, weight: .bold,     color: AppColors.success)

        view.addCard(frame: CGRect(x: 16, y: 125, width: view.frame.width - 32, height: 220))
        view.addCard(frame: CGRect(x: 16, y: 357, width: view.frame.width - 32, height: 118))
        view.addCard(frame: CGRect(x: 16, y: 487, width: view.frame.width - 32, height: 168))

        addCaption(above: totalVentasLabel,      text: "Total de ventas")
        addCaption(above: montoTotalLabel,       text: "Monto total vendido")
        addCaption(above: totalClientesLabel,    text: "Total de clientes")
        addCaption(above: totalProductosLabel,   text: "Total de productos")
        addCaption(above: menorStockNombreLabel, text: "Producto con menor stock")
        addCaption(above: menorStockCantLabel,   text: "Cantidad en stock")
        addCaption(above: subtotalFiscalLabel,   text: "Subtotal")
        addCaption(above: igvTotalLabel,         text: "IGV (18%)")
        addCaption(above: totalFiscalLabel,      text: "Total")
    }
    
    private func setupLabel(_ label: UILabel, size: CGFloat, weight: UIFont.Weight, color: UIColor) {
        label.font      = .systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.numberOfLines = 0
    }
    
    // MARK: - Cargar Reportes
    private func cargarReportes() {
        totalVentasLabel.text    = "\(ventaVM.totalVentas())"
        montoTotalLabel.text     = "S/ \(String(format: "%.2f", ventaVM.montoTotalVendido()))"
        totalClientesLabel.text  = "\(clienteVM.totalClientes())"
        totalProductosLabel.text = "\(productoVM.productos.count)"
        
        if let productoMin = productoVM.productoMenorStock() {
            menorStockNombreLabel.text = productoMin.nombre ?? "N/A"
            menorStockCantLabel.text   = "\(productoMin.stock) unidades"
        } else {
            menorStockNombreLabel.text = "Sin productos"
            menorStockCantLabel.text   = "--"
        }
        
        let subtotal = ventaVM.ventas.reduce(0) { $0 + $1.subtotal }
        let igv      = ventaVM.ventas.reduce(0) { $0 + $1.igv }
        let total    = ventaVM.montoTotalVendido()
        
        subtotalFiscalLabel.text = "S/ \(String(format: "%.2f", subtotal))"
        igvTotalLabel.text       = "S/ \(String(format: "%.2f", igv))"
        totalFiscalLabel.text    = "S/ \(String(format: "%.2f", total))"
    }
}

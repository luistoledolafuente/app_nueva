import SwiftUI
import MapKit

struct MapaSwiftUIView: View {
    @StateObject private var vm = UbicacionViewModel()
    @State private var region   = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -12.046374, longitude: -77.042793),
        span:   MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var referencia = ""
    @State private var showSaved  = false

    var body: some View {
        ZStack {
            Color.tsBg.ignoresSafeArea()
            VStack(spacing: 0) {
                mapSection
                controlPanel
            }
        }
        .navigationTitle("Mapa")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSaved = true
                } label: {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundColor(.tsRed)
                }
            }
        }
        .sheet(isPresented: $showSaved) {
            SavedLocationsView(vm: vm)
        }
        .onChange(of: vm.latitudActual) { _ in updateRegion() }
        .onChange(of: vm.longitudActual) { _ in updateRegion() }
        .onAppear { vm.solicitarPermiso() }
    }

    // MARK: - Map
    private var mapSection: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                annotationItems: vm.ubicaciones) { loc in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: loc.latitud,
                    longitude: loc.longitud
                )) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(ModuleGradient.mapa.gradient)
                                .frame(width: 36, height: 36)
                            Image(systemName: "mappin")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .shadow(color: Color.tsRed.opacity(0.5), radius: 6, x: 0, y: 3)

                        if let ref = loc.direccionReferencia, !ref.isEmpty {
                            Text(ref)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.tsText)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .shadow(radius: 3)
                        }
                    }
                }
            }
            .frame(height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 0))

            // Current location overlay
            if vm.latitudActual != 0 {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.tsRed)
                    Text("\(String(format: "%.4f", vm.latitudActual)), \(String(format: "%.4f", vm.longitudActual))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.tsText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(14)
            }
        }
    }

    // MARK: - Controls
    private var controlPanel: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Status card
                TSCard {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(ModuleGradient.mapa.gradient)
                                .frame(width: 50, height: 50)
                            Image(systemName: "location.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.permisoConcedido ? "Ubicación activa" : "Sin permiso")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.tsText)
                            if vm.latitudActual != 0 {
                                Text("Lat \(String(format: "%.5f", vm.latitudActual))  Lon \(String(format: "%.5f", vm.longitudActual))")
                                    .font(.system(size: 11))
                                    .foregroundColor(.tsSlate)
                            } else {
                                Text("Presiona obtener ubicación")
                                    .font(.caption)
                                    .foregroundColor(.tsSlate)
                            }
                        }
                        Spacer()
                        Circle()
                            .fill(vm.permisoConcedido ? Color.tsEmerald : Color.tsRed)
                            .frame(width: 10, height: 10)
                    }
                    .padding(16)
                }

                TSField(icon: "mappin.and.ellipse",
                        placeholder: "Referencia (ej. Casa, Oficina)",
                        text: $referencia)

                HStack(spacing: 12) {
                    Button {
                        vm.obtenerUbicacion()
                    } label: {
                        Label("Obtener", systemImage: "location.fill")
                    }
                    .buttonStyle(TSPrimaryButtonStyle(gradient: .mapa))

                    Button {
                        vm.direccionReferencia = referencia
                        if vm.guardarUbicacion() {
                            referencia = ""
                        }
                    } label: {
                        Label("Guardar", systemImage: "bookmark.fill")
                    }
                    .buttonStyle(TSPrimaryButtonStyle(gradient: .ventas))
                    .disabled(vm.latitudActual == 0)
                    .opacity(vm.latitudActual == 0 ? 0.5 : 1)
                }

                TSErrorBanner(message: vm.errorMessage)

                if !vm.ubicaciones.isEmpty {
                    HStack {
                        Text("Ubicaciones guardadas")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.tsSlate)
                        Spacer()
                        TSBadge(text: "\(vm.ubicaciones.count)", color: .tsRed)
                    }
                }
            }
            .padding(18)
        }
        .background(Color.tsBg)
    }

    private func updateRegion() {
        guard vm.latitudActual != 0 else { return }
        withAnimation {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: vm.latitudActual, longitude: vm.longitudActual),
                span:   MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
}

// MARK: - Saved Locations Sheet
private struct SavedLocationsView: View {
    @ObservedObject var vm: UbicacionViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tsBg.ignoresSafeArea()
                if vm.ubicaciones.isEmpty {
                    TSEmptyState(icon: "map", title: "Sin ubicaciones", subtitle: "Guarda tu primera ubicación")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(vm.ubicaciones, id: \.idUbicacion) { loc in
                                TSCard {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(ModuleGradient.mapa.gradient)
                                                .frame(width: 42, height: 42)
                                            Image(systemName: "mappin.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                        }
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(loc.direccionReferencia ?? "Sin referencia")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.tsText)
                                            Text("\(String(format: "%.4f", loc.latitud)), \(String(format: "%.4f", loc.longitud))")
                                                .font(.system(size: 12))
                                                .foregroundColor(.tsSlate)
                                            Text(formatDate(loc.fechaRegistro))
                                                .font(.caption)
                                                .foregroundColor(.tsSlate)
                                        }
                                        Spacer()
                                    }
                                    .padding(12)
                                }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        vm.eliminar(loc)
                                    } label: {
                                        Label("Eliminar", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                    }
                }
            }
            .navigationTitle("Mis Ubicaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
        }
    }
}

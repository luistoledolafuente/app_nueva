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
            Color.npBg.ignoresSafeArea()
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
                        .foregroundColor(.npOrange)
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
                                .fill(NPGradient.mapa.gradient)
                                .frame(width: 36, height: 36)
                            Image(systemName: "mappin")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .shadow(color: Color.npOrange.opacity(0.5), radius: 6, x: 0, y: 3)

                        if let ref = loc.direccionReferencia, !ref.isEmpty {
                            Text(ref)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.npPrimary)
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

            if vm.latitudActual != 0 {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.npOrange)
                    Text("\(String(format: "%.4f", vm.latitudActual)), \(String(format: "%.4f", vm.longitudActual))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.npPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(14)
            }
        }
    }

    private var controlPanel: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                NPTopCard(color: .npOrange) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(NPGradient.mapa.gradient)
                                .frame(width: 48, height: 48)
                            Image(systemName: "location.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.permisoConcedido ? "Ubicación activa" : "Sin permiso")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.npPrimary)
                            if vm.latitudActual != 0 {
                                Text("Lat \(String(format: "%.5f", vm.latitudActual))  Lon \(String(format: "%.5f", vm.longitudActual))")
                                    .font(.system(size: 11))
                                    .foregroundColor(.npSlate)
                            } else {
                                Text("Presiona obtener ubicación")
                                    .font(.caption)
                                    .foregroundColor(.npSlate)
                            }
                        }
                        Spacer()
                        Circle()
                            .fill(vm.permisoConcedido ? Color.npEmerald : Color.npDanger)
                            .frame(width: 10, height: 10)
                    }
                    .padding(14)
                }

                NPField(icon: "mappin.and.ellipse",
                        placeholder: "Referencia (ej. Casa, Oficina)",
                        text: $referencia)

                HStack(spacing: 12) {
                    Button {
                        vm.obtenerUbicacion()
                    } label: {
                        Label("Obtener", systemImage: "location.fill")
                    }
                    .buttonStyle(NPWPButtonStyle(color: .npOrange))

                    Button {
                        vm.direccionReferencia = referencia
                        if vm.guardarUbicacion() {
                            referencia = ""
                        }
                    } label: {
                        Label("Guardar", systemImage: "bookmark.fill")
                    }
                    .buttonStyle(NPWPButtonStyle(color: .npEmerald))
                    .disabled(vm.latitudActual == 0)
                    .opacity(vm.latitudActual == 0 ? 0.5 : 1)
                }

                NPErrorBanner(message: vm.errorMessage)

                if !vm.ubicaciones.isEmpty {
                    HStack {
                        Text("Ubicaciones guardadas")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.npSlate)
                        Spacer()
                        NPBadge(text: "\(vm.ubicaciones.count)", color: .npOrange)
                    }
                }
            }
            .padding(18)
        }
        .background(Color.npBg)
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

private struct SavedLocationsView: View {
    @ObservedObject var vm: UbicacionViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.npBg.ignoresSafeArea()
                if vm.ubicaciones.isEmpty {
                    NPEmptyState(icon: "map", title: "Sin ubicaciones", subtitle: "Guarda tu primera ubicación")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(vm.ubicaciones, id: \.idUbicacion) { loc in
                                NPTopCard(color: .npOrange) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(NPGradient.mapa.gradient)
                                                .frame(width: 40, height: 40)
                                            Image(systemName: "mappin.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(.white)
                                        }
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(loc.direccionReferencia ?? "Sin referencia")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.npPrimary)
                                            Text("\(String(format: "%.4f", loc.latitud)), \(String(format: "%.4f", loc.longitud))")
                                                .font(.system(size: 12))
                                                .foregroundColor(.npSlate)
                                            Text(formatDate(loc.fechaRegistro))
                                                .font(.caption)
                                                .foregroundColor(.npSlate)
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

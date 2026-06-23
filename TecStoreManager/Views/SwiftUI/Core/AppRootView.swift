import SwiftUI

struct AppRootView: View {
    @StateObject private var authVM = AuthViewModel()
    @AppStorage("darkMode") private var darkMode = false
    @State private var isLaunching = true

    var body: some View {
        ZStack {
            if isLaunching {
                LaunchView()
                    .transition(.opacity)
            } else {
                Group {
                    if authVM.estaLogueado {
                        DashboardSwiftUIView()
                            .environmentObject(authVM)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal:   .move(edge: .leading)
                            ))
                    } else {
                        LoginSwiftUIView()
                            .environmentObject(authVM)
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading),
                                removal:   .move(edge: .trailing)
                            ))
                    }
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(darkMode ? .dark : .light)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: authVM.estaLogueado)
        .onChange(of: darkMode) { newValue in
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.overrideUserInterfaceStyle = newValue ? .dark : .light
            }
        }
        .onAppear {
            // Sincronizar el estilo de la ventana al iniciar
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.overrideUserInterfaceStyle = darkMode ? .dark : .light
            }
            // Temporizador para la pantalla de lanzamiento
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeInOut(duration: 0.45)) {
                    isLaunching = false
                }
            }
        }
    }
}

// MARK: - Custom Animated Launch View
struct LaunchView: View {
    @State private var scale: CGFloat = 0.85
    @State private var opacity: Double = 0.0
    @State private var textOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // Fondo oscuro ambient
            AmbientGlowBackground()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Pulsing Storefront Logo
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 110, height: 110)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.2), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        )
                    Image(systemName: "storefront.fill")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#10B981"), Color(hex: "#3B82F6")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(scale)
                .opacity(opacity)
                .shadow(color: Color(hex: "#10B981").opacity(0.25), radius: 20)

                VStack(spacing: 8) {
                    Text("TecStore Manager")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(0.6)
                    Text("Tu tienda, tu control")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                .opacity(textOpacity)

                Spacer()

                // Loader
                ProgressView()
                    .tint(Color(hex: "#10B981"))
                    .scaleEffect(1.25)
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                textOpacity = 1.0
            }
        }
    }
}

import SwiftUI

struct AppRootView: View {
    @StateObject private var authVM = AuthViewModel()
    @AppStorage("darkMode") private var darkMode = false

    var body: some View {
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
        .preferredColorScheme(darkMode ? .dark : .light)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: authVM.estaLogueado)
        .onChange(of: darkMode) { newValue in
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.overrideUserInterfaceStyle = newValue ? .dark : .light
            }
        }
        .onAppear {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.overrideUserInterfaceStyle = darkMode ? .dark : .light
            }
        }
    }
}

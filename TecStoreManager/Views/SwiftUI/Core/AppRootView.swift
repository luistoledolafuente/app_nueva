import SwiftUI

struct AppRootView: View {
    @StateObject private var authVM = AuthViewModel()

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
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: authVM.estaLogueado)
    }
}

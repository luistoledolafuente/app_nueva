import SwiftUI

struct LoginSwiftUIView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var usuario    = ""
    @State private var password   = ""
    @State private var showReg    = false
    @State private var logoScale: CGFloat  = 0.6
    @State private var logoOpacity: Double = 0
    @State private var cardOffset: CGFloat = 60
    @State private var cardOpacity: Double = 0

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color(hex: "#3730A3"), Color(hex: "#4F46E5"), Color(hex: "#7C3AED")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative blobs
            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 320, height: 320)
                    .offset(x: geo.size.width - 100, y: -60)
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 220, height: 220)
                    .offset(x: -70, y: geo.size.height * 0.55)
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 160, height: 160)
                    .offset(x: geo.size.width * 0.4, y: geo.size.height * 0.75)
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Logo
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 110, height: 110)
                            Circle()
                                .fill(Color.white.opacity(0.10))
                                .frame(width: 90, height: 90)
                            Image(systemName: "cart.fill.badge.plus")
                                .font(.system(size: 44, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                        Text("TecStore Manager")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(logoOpacity)

                        Text("Gestión inteligente de tu tienda")
                            .font(.subheadline)
                            .foregroundColor(Color.white.opacity(0.72))
                            .opacity(logoOpacity)
                    }
                    .padding(.top, 72)
                    .padding(.bottom, 44)

                    // Form card
                    VStack(spacing: 22) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Iniciar sesión")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.tsText)
                            Text("Bienvenido de vuelta")
                                .font(.subheadline)
                                .foregroundColor(.tsSlate)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 14) {
                            TSField(icon: "person.fill",
                                    placeholder: "Usuario",
                                    text: $usuario)
                            TSField(icon: "lock.fill",
                                    placeholder: "Contraseña",
                                    text: $password,
                                    isSecure: true)
                        }

                        TSErrorBanner(message: authVM.errorMessage)

                        Button("Ingresar") {
                            withAnimation {
                                _ = authVM.login(nombreUsuario: usuario, password: password)
                            }
                        }
                        .buttonStyle(TSPrimaryButtonStyle())

                        Button {
                            showReg = true
                        } label: {
                            Group {
                                Text("¿No tienes cuenta? ")
                                    .foregroundColor(.tsSlate)
                                + Text("Regístrate")
                                    .foregroundColor(.tsIndigo)
                                    .bold()
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(26)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                    .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 12)
                    .padding(.horizontal, 20)
                    .offset(y: cardOffset)
                    .opacity(cardOpacity)

                    Spacer(minLength: 60)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) {
                logoScale   = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.spring(response: 0.65, dampingFraction: 0.80).delay(0.18)) {
                cardOffset  = 0
                cardOpacity = 1.0
            }
        }
        .sheet(isPresented: $showReg) {
            RegisterSwiftUIView().environmentObject(authVM)
        }
    }
}

// MARK: - Register View
struct RegisterSwiftUIView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var nombre   = ""
    @State private var usuario  = ""
    @State private var password = ""
    @State private var confirm  = ""
    @State private var localErr = ""
    @State private var success  = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tsBg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(ModuleGradient.clientes.gradient)
                                .frame(width: 90, height: 90)
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 10)
                        .shadow(color: Color.tsCyan.opacity(0.4), radius: 14, x: 0, y: 6)

                        TSCard {
                            VStack(spacing: 16) {
                                Text("Datos de la cuenta")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.tsText)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                TSField(icon: "person.text.rectangle",
                                        placeholder: "Nombre completo",
                                        text: $nombre)
                                TSField(icon: "at",
                                        placeholder: "Usuario",
                                        text: $usuario)
                                TSField(icon: "lock",
                                        placeholder: "Contraseña",
                                        text: $password,
                                        isSecure: true)
                                TSField(icon: "lock.shield",
                                        placeholder: "Confirmar contraseña",
                                        text: $confirm,
                                        isSecure: true)

                                TSErrorBanner(message: localErr.isEmpty ? authVM.errorMessage : localErr)

                                Button("Crear cuenta") {
                                    guard password == confirm else {
                                        localErr = "Las contraseñas no coinciden"
                                        return
                                    }
                                    localErr = ""
                                    if authVM.registrar(
                                        nombreUsuario: usuario,
                                        password: password,
                                        nombreCompleto: nombre
                                    ) { success = true }
                                }
                                .buttonStyle(TSPrimaryButtonStyle(gradient: .clientes))
                            }
                            .padding(20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Registro")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .alert("¡Cuenta creada!", isPresented: $success) {
                Button("Iniciar sesión") { dismiss() }
            } message: {
                Text("Tu cuenta fue creada exitosamente. Ya puedes iniciar sesión.")
            }
        }
    }
}

import SwiftUI

struct LoginSwiftUIView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var email       = ""
    @State private var password    = ""
    @State private var showReg     = false
    @State private var contentLoad = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0F172A"), Color(hex: "#047857")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)

                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 100, height: 100)
                            Image(systemName: "storefront.fill")
                                .font(.system(size: 44, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(y: contentLoad ? 0 : -30)
                        .opacity(contentLoad ? 1 : 0)

                        Text("TecStore Manager")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .offset(y: contentLoad ? 0 : -20)
                            .opacity(contentLoad ? 1 : 0)

                        Text("Tu tienda, tu control")
                            .font(.subheadline)
                            .foregroundColor(Color.white.opacity(0.7))
                            .offset(y: contentLoad ? 0 : -10)
                            .opacity(contentLoad ? 1 : 0)
                    }
                    .padding(.bottom, 40)

                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Accede a tu cuenta")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            Text("Ingresa tus credenciales")
                                .font(.subheadline)
                                .foregroundColor(Color.white.opacity(0.65))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 14) {
                            MPField(icon: "envelope.fill",
                                    placeholder: "Correo electrónico",
                                    text: $email,
                                    keyboardType: .emailAddress,
                                    accentColor: .white,
                                    textColor: .white,
                                    placeholderColor: Color.white.opacity(0.6),
                                    bgColor: Color.white.opacity(0.12),
                                    borderColor: Color.white.opacity(0.2))

                            MPField(icon: "lock.fill",
                                    placeholder: "Contraseña",
                                    text: $password,
                                    isSecure: true,
                                    accentColor: .white,
                                    textColor: .white,
                                    placeholderColor: Color.white.opacity(0.6),
                                    bgColor: Color.white.opacity(0.12),
                                    borderColor: Color.white.opacity(0.2))
                        }

                        MPErrorBanner(message: authVM.errorMessage)

                        Button {
                            Task { await authVM.login(email: email, password: password) }
                        } label: {
                            if authVM.isLoading {
                                ProgressView()
                                    .tint(Color(hex: "#047857"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            } else {
                                Text("Ingresar")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color(hex: "#047857"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                        .disabled(authVM.isLoading)

                        Button {
                            showReg = true
                        } label: {
                            Group {
                                Text("¿No tienes cuenta? ")
                                    .foregroundColor(Color.white.opacity(0.7))
                                + Text("Crear una")
                                    .foregroundColor(.white)
                                    .bold()
                            }
                            .font(.subheadline)
                        }
                    }
                    .offset(y: contentLoad ? 0 : 40)
                    .opacity(contentLoad ? 1 : 0)

                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { contentLoad = true }
        }
        .sheet(isPresented: $showReg) {
            RegisterSwiftUIView().environmentObject(authVM)
        }
    }
}

// MARK: - Polygon Shape
struct PolygonShape: Shape {
    let sides: Int

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for i in 0..<sides {
            let angle = (Double(i) * 360.0 / Double(sides) - 90) * .pi / 180
            let pt = CGPoint(x: center.x + CGFloat(cos(angle)) * radius,
                             y: center.y + CGFloat(sin(angle)) * radius)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Register View
struct RegisterSwiftUIView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var nombre   = ""
    @State private var email    = ""
    @State private var password = ""
    @State private var confirm  = ""
    @State private var localErr = ""
    @State private var success  = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.npBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [Color.npIndigo, Color(hex: "#4338CA")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 6)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            ZStack {
                                Circle()
                                    .fill(NPGradient.clientes.gradient)
                                    .frame(width: 80, height: 80)
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 34, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 24)
                            .shadow(color: Color.npSecondary.opacity(0.3), radius: 10, x: 0, y: 4)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Crear cuenta nueva")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.npPrimary)
                                Text("Completa tus datos para registrarte")
                                    .font(.subheadline)
                                    .foregroundColor(.npMuted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            MPCard {
                                VStack(spacing: 18) {
                                    MPField(icon: "person.text.rectangle",
                                            placeholder: "Nombre completo",
                                            text: $nombre)
                                    MPField(icon: "envelope.fill",
                                            placeholder: "Correo electrónico",
                                            text: $email,
                                            keyboardType: .emailAddress)
                                    MPField(icon: "lock",
                                            placeholder: "Contraseña",
                                            text: $password,
                                            isSecure: true)
                                    MPField(icon: "lock.shield",
                                            placeholder: "Confirmar contraseña",
                                            text: $confirm,
                                            isSecure: true)

                                    MPErrorBanner(message: localErr.isEmpty ? authVM.errorMessage : localErr)

                                    Button {
                                        guard password == confirm else {
                                            localErr = "Las contraseñas no coinciden"
                                            return
                                        }
                                        localErr = ""
                                        Task {
                                            if await authVM.register(
                                                email: email,
                                                password: password,
                                                nombreCompleto: nombre
                                            ) { success = true }
                                        }
                                    } label: {
                                        if authVM.isLoading {
                                            ProgressView()
                                                .tint(.white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 14)
                                        } else {
                                            Text("Crear cuenta")
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 14)
                                        }
                                    }
                                    .buttonStyle(MPButtonStyle(color: .npSecondary))
                                    .disabled(authVM.isLoading)
                                }
                                .padding(20)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.npPrimary)
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

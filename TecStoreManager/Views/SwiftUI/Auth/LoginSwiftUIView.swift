import SwiftUI

// MARK: - Ambient Glow Background (Neon Lights)
struct AmbientGlowBackground: View {
    var body: some View {
        ZStack {
            Color(hex: "#090D1A").ignoresSafeArea()
            
            // Neon Green/Emerald Glow (Top-Left)
            Circle()
                .fill(Color(hex: "#10B981").opacity(0.14))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: -120, y: -220)
            
            // Cobalt Indigo Glow (Bottom-Right)
            Circle()
                .fill(Color(hex: "#6366F1").opacity(0.14))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: 120, y: 220)
        }
    }
}

// MARK: - Login View
struct LoginSwiftUIView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var email       = ""
    @State private var password    = ""
    @State private var showReg     = false
    @State private var contentLoad = false

    var body: some View {
        ZStack {
            AmbientGlowBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 40)

                    // Logo & Branding Section
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 90, height: 90)
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
                                .font(.system(size: 38, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "#10B981"), Color(hex: "#3B82F6")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .shadow(color: Color(hex: "#10B981").opacity(0.2), radius: 12)
                        .scaleEffect(contentLoad ? 1 : 0.8)
                        .opacity(contentLoad ? 1 : 0)

                        Text("TecStore Manager")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(0.5)
                            .scaleEffect(contentLoad ? 1 : 0.9)
                            .opacity(contentLoad ? 1 : 0)

                        Text("Tu tienda, tu control")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.5))
                            .scaleEffect(contentLoad ? 1 : 0.95)
                            .opacity(contentLoad ? 1 : 0)
                    }
                    .padding(.bottom, 32)

                    // Floating Glassmorphic Container
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Accede a tu cuenta")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Ingresa tus credenciales de administrador")
                                .font(.system(size: 13))
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 14) {
                            MPField(icon: "envelope.fill",
                                    placeholder: "Correo electrónico",
                                    text: $email,
                                    keyboardType: .emailAddress,
                                    accentColor: Color(hex: "#10B981"),
                                    textColor: .white,
                                    placeholderColor: Color.white.opacity(0.4),
                                    bgColor: Color.white.opacity(0.06),
                                    borderColor: Color.white.opacity(0.12))

                            MPField(icon: "lock.fill",
                                    placeholder: "Contraseña",
                                    text: $password,
                                    isSecure: true,
                                    accentColor: Color(hex: "#10B981"),
                                    textColor: .white,
                                    placeholderColor: Color.white.opacity(0.4),
                                    bgColor: Color.white.opacity(0.06),
                                    borderColor: Color.white.opacity(0.12))
                        }

                        MPErrorBanner(message: authVM.errorMessage)

                        Button {
                            Task { await authVM.login(email: email, password: password) }
                        } label: {
                            if authVM.isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            } else {
                                Text("Ingresar")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                        }
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#10B981"), Color(hex: "#059669")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color(hex: "#10B981").opacity(0.3), radius: 8, x: 0, y: 4)
                        .disabled(authVM.isLoading)

                        Button {
                            showReg = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("¿No tienes cuenta?")
                                    .foregroundColor(Color.white.opacity(0.5))
                                Text("Crear una")
                                    .foregroundColor(Color(hex: "#10B981"))
                                    .bold()
                            }
                            .font(.system(size: 14))
                        }
                        .padding(.top, 4)
                    }
                    .padding(28)
                    .background(.ultraThinMaterial)
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 24, x: 0, y: 12)
                    .offset(y: contentLoad ? 0 : 40)
                    .opacity(contentLoad ? 1 : 0)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { contentLoad = true }
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
                AmbientGlowBackground()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.06))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                                Image(systemName: "person.badge.plus.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "#6366F1"), Color(hex: "#3B82F6")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .padding(.top, 24)
                            .shadow(color: Color(hex: "#6366F1").opacity(0.2), radius: 10)

                            VStack(spacing: 6) {
                                Text("Registrar Administrador")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("Completa tus datos para crear una cuenta")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.white.opacity(0.5))
                            }

                            // Glassmorphic Form Card
                            VStack(spacing: 16) {
                                MPField(icon: "person.text.rectangle",
                                        placeholder: "Nombre completo",
                                        text: $nombre,
                                        accentColor: Color(hex: "#6366F1"),
                                        textColor: .white,
                                        placeholderColor: Color.white.opacity(0.4),
                                        bgColor: Color.white.opacity(0.06),
                                        borderColor: Color.white.opacity(0.12))
                                
                                MPField(icon: "envelope.fill",
                                        placeholder: "Correo electrónico",
                                        text: $email,
                                        keyboardType: .emailAddress,
                                        accentColor: Color(hex: "#6366F1"),
                                        textColor: .white,
                                        placeholderColor: Color.white.opacity(0.4),
                                        bgColor: Color.white.opacity(0.06),
                                        borderColor: Color.white.opacity(0.12))
                                
                                MPField(icon: "lock",
                                        placeholder: "Contraseña",
                                        text: $password,
                                        isSecure: true,
                                        accentColor: Color(hex: "#6366F1"),
                                        textColor: .white,
                                        placeholderColor: Color.white.opacity(0.4),
                                        bgColor: Color.white.opacity(0.06),
                                        borderColor: Color.white.opacity(0.12))
                                
                                MPField(icon: "lock.shield",
                                        placeholder: "Confirmar contraseña",
                                        text: $confirm,
                                        isSecure: true,
                                        accentColor: Color(hex: "#6366F1"),
                                        textColor: .white,
                                        placeholderColor: Color.white.opacity(0.4),
                                        bgColor: Color.white.opacity(0.06),
                                        borderColor: Color.white.opacity(0.12))

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
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                    }
                                }
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "#6366F1"), Color(hex: "#4F46E5")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: Color(hex: "#6366F1").opacity(0.3), radius: 8, x: 0, y: 4)
                                .disabled(authVM.isLoading)
                            }
                            .padding(24)
                            .background(.ultraThinMaterial)
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 24, x: 0, y: 12)
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
                        .foregroundColor(.white)
                        .font(.system(size: 15, weight: .semibold))
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

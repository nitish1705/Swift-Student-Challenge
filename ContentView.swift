import SwiftUI
struct ContentView: View {
    @State private var isRotating = false
    @State private var loadingProgress: CGFloat = 0.0

    @State private var showNucleus = true
    @State private var showBlue = true
    @State private var showGreen = true
    @State private var showRed = true
    @State private var showYellow = true
    @State private var showOrbit = true

    @State private var expandNucleus = false
    @State private var showProfile = false
    @State private var nucleusColor = Color.orange

    @State private var particles: [ContentParticle] = []
    @State private var particleTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    struct ContentParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var opacity: Double
        var size: CGFloat
        var speed: CGFloat
    }

    func startFakeLoading() {
        loadingProgress = 0.0
        Task {
            while loadingProgress < 1.0 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                loadingProgress += 0.07
            }
            loadingProgress = 1.0
        }
    }

    func startDisappearing() {
        withAnimation { showOrbit = false }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { withAnimation { showBlue = false } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { withAnimation { showYellow = false } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { withAnimation { showGreen = false } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { withAnimation { showRed = false } }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 1.5)) {
                expandNucleus = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 2.0)) {
                nucleusColor = Color(.black)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            showProfile.toggle()
        }
    }

    // MARK: - Mesh Background

    private var meshBackground: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            if #available(iOS 18.0, *) {
                MeshGradient(
                    width: 3, height: 3,
                    points: [
                        [0, 0],
                        [Float(0.5 + 0.2 * sin(t * 0.7)), 0],
                        [1, 0],
                        [0, Float(0.5 + 0.15 * cos(t * 0.5))],
                        [Float(0.5 + 0.1 * sin(t * 0.9)), Float(0.5 + 0.1 * cos(t * 0.6))],
                        [1, Float(0.5 + 0.15 * sin(t * 0.8))],
                        [0, 1],
                        [Float(0.5 + 0.2 * cos(t * 0.6)), 1],
                        [1, 1],
                    ],
                    colors: [
                        .black, Color(red: 0.05, green: 0.0, blue: 0.15), .black,
                        Color(red: 0.0, green: 0.05, blue: 0.2), Color(red: 0.1, green: 0.0, blue: 0.2), Color(red: 0.0, green: 0.08, blue: 0.15),
                        .black, Color(red: 0.05, green: 0.05, blue: 0.1), .black,
                    ]
                )
            } else {
                LinearGradient(
                    colors: [.black, Color(red: 0.05, green: 0.0, blue: 0.15), .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    // MARK: - Particle Layer

    private func particleLayer(width: CGFloat, height: CGFloat) -> some View {
        Canvas { context, _ in
            for particle in particles {
                let rect = CGRect(
                    x: particle.x - particle.size / 2,
                    y: particle.y - particle.size / 2,
                    width: particle.size,
                    height: particle.size
                )
                context.opacity = particle.opacity
                context.fill(Circle().path(in: rect), with: .color(.white))
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private func spawnParticle(width: CGFloat, height: CGFloat) {
        guard particles.count < 35 else { return }
        particles.append(ContentParticle(
            x: CGFloat.random(in: 0...width),
            y: height + 10,
            opacity: Double.random(in: 0.1...0.4),
            size: CGFloat.random(in: 1.5...3.0),
            speed: CGFloat.random(in: 0.3...1.0)
        ))
    }

    private func updateParticles() {
        particles = particles.compactMap { p in
            var u = p
            u.y -= u.speed
            u.opacity -= 0.003
            return (u.y < -20 || u.opacity <= 0) ? nil : u
        }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let size = min(width, height)
            let atomSize = size * 0.5
            let nucleusSize = atomSize * 0.2
            let electronSize = atomSize * 0.1
            let orbitRadius = atomSize * 0.5

            let buttonWidth = size * 0.3
            let buttonHeight = size * 0.09

            ZStack {
                // ── Live mesh gradient background ──
                meshBackground
                    .ignoresSafeArea()

                // ── Floating particles ──
                particleLayer(width: width, height: height)

                // ── Main atom + controls ──
                VStack(spacing: 60) {
                    if !showProfile {
                        ZStack {
                            // Nucleus — always present, scales up to fill screen
                            Circle()
                                .fill(nucleusColor)
                                .frame(width: nucleusSize, height: nucleusSize)
                                .scaleEffect(expandNucleus ? 50.0 : 1.0)
                                .shadow(color: nucleusColor.opacity(expandNucleus ? 0 : 0.6), radius: 12)

                            // Orbit rings — hide when disappearing
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                                .frame(width: atomSize, height: atomSize)
                                .opacity(showOrbit ? 1.0 : 0.0)

                            Circle()
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                                .frame(width: atomSize * 0.7, height: atomSize * 0.7)
                                .rotationEffect(.degrees(45))
                                .opacity(showOrbit ? 1.0 : 0.0)

                            // Electrons
                            Group {
                                Circle().fill(Color.blue)
                                    .shadow(color: .blue.opacity(0.7), radius: 8)
                                    .offset(y: -orbitRadius)
                                    .opacity(showBlue ? 1.0 : 0.0)

                                Circle().fill(Color.green)
                                    .shadow(color: .green.opacity(0.7), radius: 8)
                                    .offset(y: orbitRadius)
                                    .opacity(showGreen ? 1.0 : 0.0)

                                Circle().fill(Color.red)
                                    .shadow(color: .red.opacity(0.7), radius: 8)
                                    .offset(x: orbitRadius)
                                    .opacity(showRed ? 1.0 : 0.0)

                                Circle().fill(Color.yellow)
                                    .shadow(color: .yellow.opacity(0.7), radius: 8)
                                    .offset(x: -orbitRadius)
                                    .opacity(showYellow ? 1.0 : 0.0)
                            }
                            .frame(width: electronSize, height: electronSize)
                            .rotationEffect(.degrees(isRotating ? 360 : 0))
                        }
                        .frame(width: atomSize, height: atomSize)
                    }

                    if !expandNucleus {
                        LoadingBarView(progress: $loadingProgress)
                            .padding(.horizontal, 40)
                            .opacity(loadingProgress == 1.0 ? 0 : 1.0)

                        Button("Start Journey") {
                            startFakeLoading()
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(width: buttonWidth, height: buttonHeight)
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .shadow(color: .blue.opacity(0.4), radius: 12, y: 4)
                        .opacity(loadingProgress > 0.0 ? 0.0 : 1.0)
                        .disabled(loadingProgress > 0.0)
                    }
                }

                if showProfile {
                    ProfileView()
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onReceive(particleTimer) { _ in
                spawnParticle(width: width, height: height)
                updateParticles()
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                isRotating = true
            }
        }
        .onChange(of: loadingProgress) { newValue in
            if newValue >= 1.0 {
                startDisappearing()
            }
        }
    }
}

import SwiftUI

// MARK: - Window Identity

enum WindowID: String, CaseIterable, Identifiable {
    case about = "About"
    case skills = "Skills"
    case projects = "Projects"
    case connect = "Connect"
    case info = "Info"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .about: return "person.text.rectangle"
        case .skills: return "chart.bar.fill"
        case .projects: return "folder.fill"
        case .connect: return "link"
        case .info: return "info.circle.fill"
        }
    }

    var accentColors: [Color] {
        switch self {
        case .about: return [.cyan, .blue]
        case .skills: return [.orange, .yellow]
        case .projects: return [.purple, .pink]
        case .connect: return [.green, .mint]
        case .info: return [.white, .gray]
        }
    }

    var defaultSize: CGSize {
        switch self {
        case .about: return CGSize(width: 320, height: 280)
        case .skills: return CGSize(width: 310, height: 340)
        case .projects: return CGSize(width: 330, height: 380)
        case .connect: return CGSize(width: 280, height: 220)
        case .info: return CGSize(width: 310, height: 300)
        }
    }

    /// Main app icons (left side of dock divider)
    static var mainCases: [WindowID] {
        [.about, .skills, .projects, .connect]
    }

    /// Standalone items (right side of dock divider)
    static var standaloneCases: [WindowID] {
        [.info]
    }
}

// MARK: - Window State

struct WindowState {
    var offset: CGSize
    var dragOffset: CGSize = .zero
    var zIndex: Double
    var isMinimized: Bool = false
    var minimizeProgress: CGFloat = 1.0
    var isVisible: Bool = false
}

// MARK: - HomePage

struct HomePage: View {

    @State private var windows: [WindowID: WindowState] = [:]
    @State private var topZ: Double = 10
    @State private var animateGradient = false
    @State private var particles: [HomeParticle] = []
    @State private var particleTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    @State private var showDock = false
    @State private var dockHover: WindowID? = nil
    @State private var profileScale: CGFloat = 0.0
    @State private var floatingOffset: CGFloat = 0
    @State private var showMenuBar = false

    struct HomeParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var opacity: Double
        var size: CGFloat
        var speed: CGFloat
    }

    struct SkillItem: Identifiable {
        let id = UUID()
        let icon: String
        let name: String
        let color: Color
        let level: CGFloat
    }

    struct ProjectItem: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let icon: String
        let gradient: [Color]
    }

    let skills: [SkillItem] = [
        .init(icon: "swift", name: "Swift", color: .orange, level: 0.8),
        .init(icon: "apple.logo", name: "SwiftUI", color: .blue, level: 0.75),
        .init(icon: "server.rack", name: "Backend", color: .green, level: 0.5),
        .init(icon: "paintbrush.pointed.fill", name: "UI/UX", color: .purple, level: 0.7),
    ]

    let projects: [ProjectItem] = [
        .init(title: "Atom Loader", description: "An atom-inspired animated loading screen with orbital electron paths.", icon: "atom", gradient: [.cyan, .blue]),
        .init(title: "Portfolio App", description: "This interactive portfolio built entirely in SwiftUI.", icon: "iphone.gen3", gradient: [.purple, .pink]),
        .init(title: "Type Engine", description: "Terminal-style typewriter text engine with haptic feedback.", icon: "keyboard.fill", gradient: [.green, .mint]),
        .init(title: "Experiments", description: "SwiftUI animation experiments pushing creative boundaries.", icon: "flask.fill", gradient: [.orange, .yellow]),
    ]

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ZStack {
                meshBackground.ignoresSafeArea()

                particleLayer(width: width, height: height)

                ForEach(WindowID.allCases) { windowID in
                    if let state = windows[windowID], state.isVisible, !state.isMinimized {
                        desktopWindow(id: windowID, state: state, screenSize: geo.size)
                            .zIndex(state.zIndex)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.5).combined(with: .opacity),
                                removal: .scale(scale: 0.3).combined(with: .opacity)
                            ))
                    }
                }

                if showMenuBar {
                    menuBar(width: width)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if showDock {
                    VStack {
                        Spacer()
                        dock(screenWidth: width)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .ignoresSafeArea(edges: .bottom)
                }
            }
            .onAppear {
                initializeWindows(screenSize: geo.size)
                triggerEntrance()
            }
            .onReceive(particleTimer) { _ in
                spawnParticle(width: width, height: height)
                updateParticles()
            }
        }
    }

    // MARK: - Initialize Windows

    private func initializeWindows(screenSize: CGSize) {
        let centerX = screenSize.width / 2
        let centerY = screenSize.height / 2

        for (index, windowID) in WindowID.allCases.enumerated() {
            let cascadeOffset = CGFloat(index) * 30
            windows[windowID] = WindowState(
                offset: CGSize(
                    width: centerX - windowID.defaultSize.width / 2 + cascadeOffset - 40,
                    height: centerY - windowID.defaultSize.height / 2 + cascadeOffset - 80
                ),
                zIndex: Double(index),
                isVisible: false
            )
        }
        topZ = Double(WindowID.allCases.count)
    }

    // MARK: - Entrance

    private func triggerEntrance() {
        animateGradient = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showMenuBar = true
            }
        }

        // Only cascade the main 4 windows on entrance
        for (index, windowID) in WindowID.mainCases.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + Double(index) * 0.25) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                    windows[windowID]?.isVisible = true
                }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + Double(WindowID.mainCases.count) * 0.25 + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showDock = true
            }
        }
    }

    // MARK: - Desktop Window

    private func desktopWindow(id: WindowID, state: WindowState, screenSize: CGSize) -> some View {
        let currentOffset = CGSize(
            width: state.offset.width + state.dragOffset.width,
            height: state.offset.height + state.dragOffset.height
        )

        return VStack(spacing: 0) {
            windowTitleBar(id: id)
            windowContent(id: id)
        }
        .frame(width: min(id.defaultSize.width, screenSize.width - 32))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.25), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
        .scaleEffect(state.dragOffset != .zero ? 1.02 : 1.0)
        .offset(currentOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    windows[id]?.dragOffset = value.translation
                    bringToFront(id)
                }
                .onEnded { value in
                    windows[id]?.offset.width += value.translation.width
                    windows[id]?.offset.height += value.translation.height
                    windows[id]?.dragOffset = .zero
                }
        )
        .onTapGesture {
            bringToFront(id)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: state.dragOffset)
    }

    // MARK: - Title Bar

    private func windowTitleBar(id: WindowID) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red.opacity(0.9))
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color.red.opacity(0.5), lineWidth: 0.5))
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        windows[id]?.isVisible = false
                    }
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }

            Circle()
                .fill(Color.yellow.opacity(0.9))
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color.yellow.opacity(0.5), lineWidth: 0.5))
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        windows[id]?.isMinimized = true
                    }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }

            Circle()
                .fill(Color.green.opacity(0.9))
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color.green.opacity(0.5), lineWidth: 0.5))

            Spacer()

            Image(systemName: id.icon)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))

            Text(id.rawValue)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            Color.clear.frame(width: 52, height: 12)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            ZStack {
                Color.black.opacity(0.3)
                LinearGradient(
                    colors: id.accentColors.map { $0.opacity(0.08) },
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: - Content Router

    @ViewBuilder
    private func windowContent(id: WindowID) -> some View {
        switch id {
        case .about:
            aboutContent()
        case .skills:
            skillsContent()
        case .projects:
            projectsContent()
        case .connect:
            connectContent()
        case .info:
            infoContent()
        }
    }

    // MARK: - About Content

    private func aboutContent() -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.cyan, .purple, .pink, .orange, .cyan],
                            center: .center
                        ),
                        lineWidth: 2.5
                    )
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(animateGradient ? 360 : 0))
                    .blur(radius: 3)
                    .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: animateGradient)

                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.cyan, .purple, .pink, .orange, .cyan],
                            center: .center
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(animateGradient ? 360 : 0))
                    .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: animateGradient)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.3)],
                            center: .center,
                            startRadius: 3,
                            endRadius: 38
                        )
                    )
                    .frame(width: 76, height: 76)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(
                                LinearGradient(colors: [.white, .cyan.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                            )
                    )
            }

            Text("Nitish")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.white, .cyan], startPoint: .leading, endPoint: .trailing)
                )

            Text("iOS Developer · Creative Coder")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)

            Divider().background(Color.white.opacity(0.1))

            HStack(spacing: 4) {
                Image(systemName: "quote.opening")
                    .foregroundColor(.cyan.opacity(0.5))
                    .font(.caption2)
                Text("Curious, learning, and evolving — one build at a time.")
                    .font(.system(size: 12, weight: .regular, design: .serif))
                    .foregroundColor(.white.opacity(0.75))
                    .italic()
                    .lineSpacing(4)
                Image(systemName: "quote.closing")
                    .foregroundColor(.cyan.opacity(0.5))
                    .font(.caption2)
            }
            .multilineTextAlignment(.center)
        }
        .padding(20)
    }

    // MARK: - Skills Content

    private func skillsContent() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(skills) { skill in
                HStack(spacing: 12) {
                    Image(systemName: skill.icon)
                        .font(.system(size: 16))
                        .foregroundColor(skill.color)
                        .frame(width: 28)

                    Text(skill.name)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 65, alignment: .leading)

                    GeometryReader { barGeo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.08))

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [skill.color, skill.color.opacity(0.4)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: barGeo.size.width * skill.level)
                                .shadow(color: skill.color.opacity(0.5), radius: 4)
                        }
                    }
                    .frame(height: 6)

                    Text("\(Int(skill.level * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(skill.color)
                        .frame(width: 36)
                }
            }

            Divider().background(Color.white.opacity(0.1))

            HStack(spacing: 6) {
                Circle().fill(Color.green).frame(width: 6, height: 6)
                Text("system active — all modules loaded")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.green.opacity(0.6))
            }
        }
        .padding(20)
    }

    // MARK: - Projects Content

    private func projectsContent() -> some View {
        VStack(spacing: 12) {
            ForEach(projects) { project in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: project.gradient.map { $0.opacity(0.25) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 42, height: 42)

                        Image(systemName: project.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(
                                LinearGradient(colors: project.gradient, startPoint: .top, endPoint: .bottom)
                            )
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(project.title)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(project.description)
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.55))
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                        )
                )
            }
        }
        .padding(16)
    }

    // MARK: - Connect Content

    private func connectContent() -> some View {
        VStack(spacing: 16) {
            ForEach([
                ("envelope.fill", "Email", [Color.blue, Color.cyan], "hello@nitish.dev"),
                ("chevron.left.forwardslash.chevron.right", "GitHub", [Color.purple, Color.pink], "github.com/nitish"),
                ("network", "Website", [Color.orange, Color.yellow], "nitish.dev"),
            ], id: \.1) { icon, label, colors, detail in
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: colors.map { $0.opacity(0.2) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle().stroke(
                                    LinearGradient(
                                        colors: colors.map { $0.opacity(0.4) },
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.8
                                )
                            )

                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundStyle(
                                LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                            )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Text(detail)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(20)
    }

    // MARK: - Info Content (placeholder — fill in your text later)

    private func infoContent() -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {

                // Header
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                    Text("About This Project")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                }

                Divider().background(Color.white.opacity(0.1))

                // Description — replace this text with whatever you want
                Text("This project reimagines what a portfolio can be. Rather than presenting information as static sections on a screen, I designed this app as a guided interaction — beginning with a terminal-inspired interface that reflects my technical roots, then unfolding into a tactile, matchbook-style layout that represents exploration and discovery.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .lineSpacing(5)

                Text("The goal was not only to showcase my work, but to demonstrate how I approach problem-solving: structured, intentional, and experience-driven. Every transition, animation, and layout decision was crafted to communicate personality through motion and hierarchy. This portfolio is both a reflection of my current skills in SwiftUI and a statement about the kind of developer I aspire to become — one who builds interfaces that feel alive, thoughtful, and human.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .lineSpacing(5)


                Divider().background(Color.white.opacity(0.1))

                // Version / meta info
                HStack(spacing: 6) {
                    Circle().fill(Color.white.opacity(0.3)).frame(width: 5, height: 5)
                    Text("v1.0 — Designed & developed by Nitish using SwiftUI")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.35))
                }
            }
            .padding(20)
        }
    }

    // MARK: - Menu Bar

    private func menuBar(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "apple.logo")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))

                Text("Nitish's Portfolio")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                Text("Sat Feb 14  9:41 AM")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                }
            )
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 0.5),
                alignment: .bottom
            )

            Spacer()
        }
    }

    // MARK: - Dock (with vertical divider)

    private func dock(screenWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            // ── Main app icons (left side) ──
            HStack(spacing: 12) {
                ForEach(WindowID.mainCases) { windowID in
                    dockIcon(windowID: windowID)
                }
            }

            // ── Vertical divider (macOS style) ──
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.white.opacity(0.2))
                .frame(width: 1.5, height: 36)
                .padding(.horizontal, 14)

            // ── Standalone icons (right side) ──
            HStack(spacing: 12) {
                ForEach(WindowID.standaloneCases) { windowID in
                    dockIcon(windowID: windowID)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                Capsule()
                    .fill(Color.white.opacity(0.06))
                Capsule()
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
            }
        )
        .padding(.bottom, 16)
    }

    private func dockIcon(windowID: WindowID) -> some View {
        let isOpen = windows[windowID]?.isVisible == true && windows[windowID]?.isMinimized != true
        let isHovering = dockHover == windowID

        return VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: windowID.accentColors.map { $0.opacity(isOpen ? 0.4 : 0.15) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: windowID.accentColors.map { $0.opacity(0.5) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isOpen ? 1.2 : 0.5
                            )
                    )

                Image(systemName: windowID.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(colors: windowID.accentColors, startPoint: .top, endPoint: .bottom)
                    )
            }
            .scaleEffect(isHovering ? 1.25 : 1.0)
            .offset(y: isHovering ? -8 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)

            Circle()
                .fill(windowID.accentColors[0])
                .frame(width: 4, height: 4)
                .opacity(isOpen ? 1.0 : 0.0)

            if isHovering {
                Text(windowID.rawValue)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                    )
                    .transition(.opacity.combined(with: .offset(y: 4)))
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                if windows[windowID]?.isMinimized == true {
                    windows[windowID]?.isMinimized = false
                    bringToFront(windowID)
                } else if windows[windowID]?.isVisible == true {
                    windows[windowID]?.isMinimized = true
                } else {
                    windows[windowID]?.isVisible = true
                    bringToFront(windowID)
                }
            }
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        .onLongPressGesture(minimumDuration: 0.01, pressing: { pressing in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                dockHover = pressing ? windowID : nil
            }
        }, perform: {})
    }

    // MARK: - Bring to Front

    private func bringToFront(_ id: WindowID) {
        topZ += 1
        windows[id]?.zIndex = topZ
    }

    // MARK: - Mesh Background

    private var meshBackground: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            if #available(iOS 18.0, *) {
                MeshGradient(
                    width: 3, height: 3,
                    points: [
                        [0, 0],
                        [Float(0.5 + 0.2 * sin(t * 0.7)), 0],
                        [1, 0],
                        [0, Float(0.5 + 0.15 * cos(t * 0.5))],
                        [Float(0.5 + 0.1 * sin(t * 0.9)), Float(0.5 + 0.1 * cos(t * 0.6))],
                        [1, Float(0.5 + 0.15 * sin(t * 0.8))],
                        [0, 1],
                        [Float(0.5 + 0.2 * cos(t * 0.6)), 1],
                        [1, 1],
                    ],
                    colors: [
                        .black, Color(red: 0.05, green: 0.0, blue: 0.15), .black,
                        Color(red: 0.0, green: 0.05, blue: 0.2), Color(red: 0.1, green: 0.0, blue: 0.2), Color(red: 0.0, green: 0.08, blue: 0.15),
                        .black, Color(red: 0.05, green: 0.05, blue: 0.1), .black,
                    ]
                )
            } else {
                LinearGradient(
                    colors: [.black, Color(red: 0.05, green: 0.0, blue: 0.15), .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    // MARK: - Particles

    private func particleLayer(width: CGFloat, height: CGFloat) -> some View {
        Canvas { context, _ in
            for particle in particles {
                let rect = CGRect(
                    x: particle.x - particle.size / 2,
                    y: particle.y - particle.size / 2,
                    width: particle.size,
                    height: particle.size
                )
                context.opacity = particle.opacity
                context.fill(Circle().path(in: rect), with: .color(.white))
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private func spawnParticle(width: CGFloat, height: CGFloat) {
        guard particles.count < 35 else { return }
        particles.append(HomeParticle(
            x: CGFloat.random(in: 0...width),
            y: height + 10,
            opacity: Double.random(in: 0.1...0.4),
            size: CGFloat.random(in: 1.5...3.0),
            speed: CGFloat.random(in: 0.3...1.0)
        ))
    }

    private func updateParticles() {
        particles = particles.compactMap { p in
            var u = p
            u.y -= u.speed
            u.opacity -= 0.003
            return (u.y < -20 || u.opacity <= 0) ? nil : u
        }
    }
}

// MARK: - ProfileView (Page 1 → ProfileView2)

struct ProfileView: View {
    @State private var typedText = ""
    @State private var textFinished = false
    @State private var isVisible = false
    @State private var showNextPage = false

    let fullText = "This project grew out of experimentation.\n It's the result of trying things, breaking them, fixing them, and learning how ideas slowly turn into experiences.\n\nI'm currently exploring Swift and SwiftUI, learning by building rather than waiting to feel ready.\n\nI enjoy the process of figuring things out.\n Watching small design and logic choices change how an app feels.\n\nEven when I don't have all the answers, I like moving forward, asking better questions, and improving step by step.\n\nThis project isn't an endpoint.\nIt's simply a snapshot of where I am right now—curious, learning, and evolving.\n"

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let buttonWidth = width * 0.45
            let buttonHeight = width * 0.12

            ZStack {
                Color(.black)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        HStack {
                            Text(typedText)
                                .font(.system(.title3, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                        .padding(.horizontal, 30)

                        Spacer()

                        if textFinished {
                            Button {
                                eraseText()
                            } label: {
                                Text("Next?")
                                    .font(.system(.headline, design: .monospaced))
                                    .foregroundColor(.green)
                                    .frame(width: buttonWidth, height: buttonHeight)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: buttonHeight / 2)
                                            .stroke(.green, lineWidth: 2)
                                    )
                                    .opacity(isVisible ? 1.0 : 0.6)
                                    .scaleEffect(isVisible ? 1.0 : 0.85)
                            }
                            .onAppear {
                                withAnimation(
                                    .easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true)
                                ) {
                                    isVisible.toggle()
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(.top, geo.safeAreaInsets.top + 20)
                    .frame(width: geo.size.width)
                }

                if showNextPage {
                    ProfileView2()
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            startTyping()
        }
    }

    func startTyping() {
        typedText = ""
        Task {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            for char in fullText {
                try? await Task.sleep(nanoseconds: 800_000)
                typedText.append(char)
                generator.impactOccurred()
            }
            await MainActor.run {
                textFinished = true
            }
        }
    }

    func eraseText() {
        textFinished = false
        Task {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()

            while true {
                try? await Task.sleep(nanoseconds: 5_000_000)

                let didRemove = await MainActor.run { () -> Bool in
                    guard !typedText.isEmpty else { return false }
                    typedText.removeLast()
                    return true
                }

                if didRemove {
                    generator.impactOccurred()
                } else {
                    break
                }
            }

            await MainActor.run {
                withAnimation(.easeInOut(duration: 2)) {
                    showNextPage = true
                }
            }
        }
    }
}

// MARK: - ProfileView2 (Page 2 → HomePage)

struct ProfileView2: View {
    @State private var typedText = ""
    @State private var isTextFinished = false
    @State private var showHomePage = false
    @State private var isVisible = false

    let fullText = "\nI should probably start with an introduction.\n\n Hey, I'm Nitish.\n\nI started coding out of curiosity, and along the way it became something I genuinely enjoy.\n\nI like exploring unfamiliar ideas, learning from mistakes, and growing through building.\n\nI don't know everything yet, but I'm always ready to learn, experiment, and move forward.\n\nThis project is just one step in that ongoing journey.\n"

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let buttonWidth = width * 0.45
            let buttonHeight = width * 0.12

            ZStack {
                Color.black.ignoresSafeArea()

                VStack {
                    HStack {
                        Text(typedText)
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.green)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding(.horizontal, 30)

                    Spacer()

                    if isTextFinished {
                        Button {
                            eraseText()
                        } label: {
                            Text("Next?")
                                .font(.system(.headline, design: .monospaced))
                                .foregroundColor(.green)
                                .frame(width: buttonWidth, height: buttonHeight)
                                .overlay(
                                    RoundedRectangle(cornerRadius: buttonHeight / 2)
                                        .stroke(.green, lineWidth: 2)
                                )
                                .opacity(isVisible ? 1.0 : 0.6)
                                .scaleEffect(isVisible ? 1.0 : 0.85)
                        }
                        .onAppear {
                            withAnimation(
                                .easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true)
                            ) {
                                isVisible.toggle()
                            }
                        }
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .safeAreaInset(edge: .top) {
                    Color.clear.frame(height: 0)
                }

                if showHomePage {
                    HomePage()
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                startTyping()
            }
        }
    }

    func startTyping() {
        typedText = ""
        Task {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            for char in fullText {
                try? await Task.sleep(nanoseconds: 800_000)
                typedText.append(char)
                generator.impactOccurred()
            }
            await MainActor.run {
                isTextFinished = true
            }
        }
    }

    func eraseText() {
        isTextFinished = false
        Task {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()

            while true {
                try? await Task.sleep(nanoseconds: 5_000_000)

                let didRemove = await MainActor.run { () -> Bool in
                    guard !typedText.isEmpty else { return false }
                    typedText.removeLast()
                    return true
                }

                if didRemove {
                    generator.impactOccurred()
                } else {
                    break
                }
            }

            await MainActor.run {
                isTextFinished = false
                withAnimation(.easeInOut(duration: 2)) {
                    showHomePage = true
                }
            }
        }
    }
}

// MARK: - LoadingBarView

struct LoadingBarView: View {
    @Binding var progress: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 20)
                    .foregroundStyle(Color.gray.opacity(0.3))

                RoundedRectangle(cornerRadius: 20)
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: geometry.size.width * progress)
                    .animation(.easeOut, value: progress)
            }
        }
        .frame(height: 20)
    }
}

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
            opacity: Double.random(in: 0.15...0.5),
            size: CGFloat.random(in: 1.5...3.0),
            speed: CGFloat.random(in: 0.8...2.5)
        ))
    }

    private func updateParticles() {
        particles = particles.compactMap { p in
            var u = p
            u.y -= u.speed
            u.opacity -= 0.0008
            return (u.y < -20 || u.opacity <= 0) ? nil : u
        }
    }

    // MARK: - Body

    var body: some View {
        if #available(iOS 17.0, *) {
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
                    meshBackground
                        .ignoresSafeArea()
                    
                    particleLayer(width: width, height: height)
                    
                    VStack(spacing: 60) {
                        if !showProfile {
                            ZStack {
                                Circle()
                                    .fill(nucleusColor)
                                    .frame(width: nucleusSize, height: nucleusSize)
                                    .scaleEffect(expandNucleus ? 50.0 : 1.0)
                                    .shadow(color: nucleusColor.opacity(expandNucleus ? 0 : 0.6), radius: 12)
                                
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                                    .frame(width: atomSize, height: atomSize)
                                    .opacity(showOrbit ? 1.0 : 0.0)
                                
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
            .onChange(of: loadingProgress) { oldValue, newValue in
                if newValue >= 1.0 { startDisappearing() }
            }
        }
    }
}


// MARK: - Window Identity

enum WindowID: String, CaseIterable, Identifiable {
    case about = "About"
    case skills = "Skills"
    case projects = "Projects"
    case connect = "Connect"
    case education = "Education"
    case hobbies = "Hobbies"
    case music = "Music"
    case chess = "Chess"
    case gaming = "Gaming"
    case info = "Info"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .about: return "person.text.rectangle"
        case .skills: return "chart.bar.fill"
        case .projects: return "folder.fill"
        case .connect: return "link"
        case .education: return "graduationcap.fill"
        case .hobbies: return "bicycle"
        case .music: return "headphones"
        case .chess: return "crown.fill"
        case .gaming: return "gamecontroller.fill"
        case .info: return "info.circle.fill"
        }
    }

    var accentColors: [Color] {
        switch self {
        case .about: return [.cyan, .blue]
        case .skills: return [.orange, .yellow]
        case .projects: return [.purple, .pink]
        case .connect: return [.green, .mint]
        case .education: return [.indigo, .blue]
        case .hobbies: return [.orange, .red]
        case .music: return [.pink, .purple]
        case .chess: return [.yellow, .orange]
        case .gaming: return [.green, .cyan]
        case .info: return [.white, .gray]
        }
    }

    func defaultSize(for screenSize: CGSize) -> CGSize {
        let w = screenSize.width
        let h = screenSize.height
        let boxW = w * 0.72
        let boxH = h * 0.32
        switch self {
        case .about:     return CGSize(width: boxW, height: boxH)
        case .skills:    return CGSize(width: boxW, height: boxH)
        case .projects:  return CGSize(width: boxW, height: boxH * 1.1)
        case .connect:   return CGSize(width: boxW * 0.95, height: boxH * 0.9)
        case .education: return CGSize(width: boxW, height: boxH)
        case .hobbies:   return CGSize(width: boxW * 0.95, height: boxH * 0.9)
        case .music:     return CGSize(width: boxW * 0.92, height: boxH * 0.9)
        case .chess:     return CGSize(width: boxW * 0.95, height: boxH)
        case .gaming:    return CGSize(width: boxW * 0.92, height: boxH * 0.88)
        case .info:      return CGSize(width: boxW, height: boxH * 1.05)
        }
    }

    static var professionalCases: [WindowID] { [.about, .skills, .projects, .connect, .education] }
    static var personalCases: [WindowID] { [.hobbies, .music, .chess, .gaming] }
    static var standaloneCases: [WindowID] { [.info] }
    static var mainCases: [WindowID] { [.about, .skills, .projects, .connect] }
}

// MARK: - Window State

struct WindowState {
    var offset: CGSize
    var dragOffset: CGSize = .zero
    var zIndex: Double
    var isMinimized: Bool = false
    var isVisible: Bool = false
    var isFullscreen: Bool = false
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
    @State private var showMenuBar = false
    @State private var currentScreenSize: CGSize = .zero

    private let menuBarHeight: CGFloat = 36
    private let dockAreaHeight: CGFloat = 70

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
        .init(icon: "swift", name: "Swift", color: .orange, level: 0.85),
        .init(icon: "apple.logo", name: "SwiftUI", color: .blue, level: 0.80),
        .init(icon: "database.fill", name: "SwiftData", color: .green, level: 0.75),
        .init(icon: "cup.and.saucer.fill", name: "Java", color: .red, level: 0.85),
        .init(icon: "c.square.fill", name: "C", color: .purple, level: 0.75),
    ]

    let projects: [ProjectItem] = [
        .init(title: "CodeSnippet", description: "A SwiftUI-based mini IDE for organizing reusable code snippets with folder-based structure.", icon: "chevron.left.forwardslash.chevron.right", gradient: [.cyan, .blue]),
        .init(title: "GPACALC", description: "An academic utility application to calculate GPA and CGPA with persistent storage.", icon: "graduationcap.fill", gradient: [.green, .mint]),
        .init(title: "Portfolio App", description: "An interactive portfolio built entirely in SwiftUI.", icon: "person.crop.circle.fill", gradient: [.purple, .pink]),
        .init(title: "Password Generator", description: "A cybersecurity utility built to handle password complexity and encryption.", icon: "key.fill", gradient: [.orange, .red]),
    ]

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                meshBackground.ignoresSafeArea()
                particleLayer(width: size.width, height: size.height)

                ForEach(WindowID.allCases) { windowID in
                    if let state = windows[windowID], state.isVisible, !state.isMinimized {
                        desktopWindow(id: windowID, state: state, screenSize: size)
                            .zIndex(state.zIndex)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.5).combined(with: .opacity),
                                removal: .scale(scale: 0.3).combined(with: .opacity)
                            ))
                    }
                }
                VStack {
                    if showMenuBar {
                        menuBar(width: size.width)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    Spacer()
                }
                .zIndex(9999)
                VStack {
                    Spacer()
                    if showDock {
                        ZStack(alignment: .top) {
                            // Tooltip floats above dock
                            if let hoveredID = dockHover {
                                dockTooltip(for: hoveredID)
                                    .offset(y: -52)
                                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                                    .zIndex(1)
                            }

                            dockView(screenWidth: size.width)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .zIndex(9998)
                .ignoresSafeArea(edges: .bottom)
            }
            .onChange(of: size) { newSize in
                currentScreenSize = newSize
            }
            .onAppear {
                currentScreenSize = size
                initializeWindows(screenSize: size)
                triggerEntrance()
            }
            .onReceive(particleTimer) { _ in
                spawnParticle(width: size.width, height: size.height)
                updateParticles()
            }
        }
    }

    // MARK: - Initialize Windows (centered)

    private func initializeWindows(screenSize: CGSize) {
        for (index, windowID) in WindowID.allCases.enumerated() {
            let winSize = windowID.defaultSize(for: screenSize)
            let x = (screenSize.width - winSize.width) / 2
            let y = (screenSize.height - winSize.height) / 2
            let cascade = CGFloat(index % 5) * 18

            windows[windowID] = WindowState(
                offset: CGSize(width: x + cascade - 36, height: y + cascade - 36),
                zIndex: Double(index),
                isVisible: false
            )
        }
        topZ = Double(WindowID.allCases.count)
    }

    // MARK: - Clamp window position within bounds

    private func clampedOffset(for id: WindowID, proposed: CGSize, screenSize: CGSize) -> CGSize {
        let winSize = id.defaultSize(for: screenSize)
        let minX: CGFloat = 0
        let minY: CGFloat = menuBarHeight
        let maxX: CGFloat = screenSize.width - winSize.width
        let maxY: CGFloat = screenSize.height - dockAreaHeight - winSize.height

        return CGSize(
            width: min(max(proposed.width, minX), maxX),
            height: min(max(proposed.height, minY), maxY)
        )
    }

    // MARK: - Entrance

    private func triggerEntrance() {
        animateGradient = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { showMenuBar = true }
        }

        for (index, windowID) in WindowID.mainCases.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + Double(index) * 0.25) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                    windows[windowID]?.isVisible = true
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + Double(WindowID.mainCases.count) * 0.25 + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { showDock = true }
        }
    }

    // MARK: - Desktop Window

    private func desktopWindow(id: WindowID, state: WindowState, screenSize: CGSize) -> some View {
        let fs = state.isFullscreen
        let winSize = id.defaultSize(for: screenSize)
        let windowWidth = fs ? screenSize.width : winSize.width
        let windowHeight = fs ? screenSize.height : winSize.height

        let baseOffset = CGSize(
            width: state.offset.width + state.dragOffset.width,
            height: state.offset.height + state.dragOffset.height
        )
        let clampedOff = clampedOffset(for: id, proposed: baseOffset, screenSize: screenSize)
        let currentOffset: CGSize = fs ? .zero : clampedOff

        return VStack(spacing: 0) {
            if fs { Color.clear.frame(height: 38) }
            windowTitleBar(id: id, isFullscreen: fs)
            windowContent(id: id, isFullscreen: fs)
        }
        .frame(width: windowWidth, height: windowHeight)
        .clipShape(RoundedRectangle(cornerRadius: fs ? 0 : 14, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: fs ? 0 : 14, style: .continuous)
                .fill(.ultraThinMaterial).environment(\.colorScheme, .dark)
        )
        .overlay(
            fs ? nil :
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.25), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.8
                )
        )
        .scaleEffect(!fs && state.dragOffset != .zero ? 1.02 : 1.0)
        .position(
            x: fs ? screenSize.width / 2 : currentOffset.width + windowWidth / 2,
            y: fs ? screenSize.height / 2 : currentOffset.height + windowHeight / 2
        )
        .gesture(
            fs ? nil :
                DragGesture()
                .onChanged { value in
                    windows[id]?.dragOffset = value.translation
                    bringToFront(id)
                }
                .onEnded { value in
                    let proposed = CGSize(
                        width: (windows[id]?.offset.width ?? 0) + value.translation.width,
                        height: (windows[id]?.offset.height ?? 0) + value.translation.height
                    )
                    let clamped = clampedOffset(for: id, proposed: proposed, screenSize: screenSize)
                    windows[id]?.offset = clamped
                    windows[id]?.dragOffset = .zero
                }
        )
        .onTapGesture { bringToFront(id) }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: fs)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: state.dragOffset)
    }

    // MARK: - Title Bar

    private func windowTitleBar(id: WindowID, isFullscreen: Bool) -> some View {
        HStack(spacing: 8) {
            Circle().fill(Color.red.opacity(0.9)).frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color.red.opacity(0.5), lineWidth: 0.5))
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        windows[id]?.isFullscreen = false; windows[id]?.isVisible = false
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }

            Circle().fill(Color.yellow.opacity(0.9)).frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color.yellow.opacity(0.5), lineWidth: 0.5))
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        windows[id]?.isFullscreen = false; windows[id]?.isMinimized = true
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }

            Circle().fill(Color.green.opacity(0.9)).frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color.green.opacity(0.5), lineWidth: 0.5))
                .onTapGesture {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                        let goingFullscreen = !(windows[id]?.isFullscreen ?? false)
                        windows[id]?.isFullscreen = goingFullscreen
                        if goingFullscreen { bringToFront(id) }
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }

            Spacer()
            Image(systemName: id.icon).font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
            Text(id.rawValue).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(.white.opacity(0.7))
            Spacer()
            Color.clear.frame(width: 52, height: 12)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(
            ZStack {
                Color.black.opacity(0.3)
                LinearGradient(colors: id.accentColors.map { $0.opacity(0.08) }, startPoint: .leading, endPoint: .trailing)
            }
        )
        .overlay(Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5), alignment: .bottom)
    }

    // MARK: - Content Router

    @ViewBuilder
    private func windowContent(id: WindowID, isFullscreen: Bool) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            Group {
                switch id {
                case .about: aboutContent(isFullscreen: isFullscreen)
                case .skills: skillsContent(isFullscreen: isFullscreen)
                case .projects: projectsContent(isFullscreen: isFullscreen)
                case .connect: connectContent(isFullscreen: isFullscreen)
                case .education: educationContent(isFullscreen: isFullscreen)
                case .hobbies: hobbiesContent(isFullscreen: isFullscreen)
                case .music: musicContent(isFullscreen: isFullscreen)
                case .chess: chessContent(isFullscreen: isFullscreen)
                case .gaming: gamingContent(isFullscreen: isFullscreen)
                case .info: infoContent(isFullscreen: isFullscreen)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - About

    private func aboutContent(isFullscreen: Bool) -> some View {
        VStack(spacing: isFullscreen ? 24 : 14) {
            ZStack {
                Circle()
                    .stroke(AngularGradient(colors: [.cyan, .purple, .pink, .orange, .cyan], center: .center), lineWidth: 2.5)
                    .frame(width: isFullscreen ? 120 : 70, height: isFullscreen ? 120 : 70)
                    .rotationEffect(.degrees(animateGradient ? 360 : 0)).blur(radius: 3)
                    .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: animateGradient)
                Circle()
                    .stroke(AngularGradient(colors: [.cyan, .purple, .pink, .orange, .cyan], center: .center), lineWidth: 1.5)
                    .frame(width: isFullscreen ? 120 : 70, height: isFullscreen ? 120 : 70)
                    .rotationEffect(.degrees(animateGradient ? 360 : 0))
                    .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: animateGradient)
                Image("profileImage")
                    .resizable()
                    .scaledToFill()
                    .frame(width: isFullscreen ? 96 : 58, height: isFullscreen ? 96 : 58)
                    .clipShape(Circle())
            }

            Text("Nitish").font(.system(size: isFullscreen ? 32 : 20, weight: .bold, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [.white, .cyan], startPoint: .leading, endPoint: .trailing))
            Text("iOS Developer · Creative Coder").font(.system(size: isFullscreen ? 14 : 10, weight: .medium, design: .monospaced)).foregroundColor(.gray)

            if isFullscreen {
                Text("3rd Year B.E. · St. Joseph's Institute of Technology, Chennai")
                    .font(.system(size: 13, weight: .regular, design: .rounded)).foregroundColor(.white.opacity(0.5))
            }

            Divider().background(Color.white.opacity(0.1))

            HStack(spacing: 4) {
                Image(systemName: "quote.opening").foregroundColor(.cyan.opacity(0.5)).font(.caption2)
                Text("I don't wait to feel ready — I just start building.")
                    .font(.system(size: isFullscreen ? 14 : 10, weight: .regular, design: .serif))
                    .foregroundColor(.white.opacity(0.75)).italic()
                Image(systemName: "quote.closing").foregroundColor(.cyan.opacity(0.5)).font(.caption2)
            }.multilineTextAlignment(.center)

            if isFullscreen {
                Divider().background(Color.white.opacity(0.1))
                VStack(spacing: 8) {
                    statRow(icon: "hammer.fill", label: "Builder", value: "4+ projects shipped")
                    statRow(icon: "brain.head.profile", label: "LeetCode", value: "Active problem solver")
                    statRow(icon: "swift", label: "Primary", value: "Swift & SwiftUI")
                    statRow(icon: "puzzlepiece.fill", label: "Fun fact", value: "Tournament chess player")
                }
            }
        }
        .padding(isFullscreen ? 32 : 14)
    }

    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(.cyan.opacity(0.7)).frame(width: 24)
            Text(label).font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundColor(.white.opacity(0.6)).frame(width: 70, alignment: .leading)
            Text(value).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundColor(.white.opacity(0.8))
            Spacer()
        }
    }

    // MARK: - Skills

    private func skillsContent(isFullscreen: Bool) -> some View {
        VStack(alignment: .leading, spacing: isFullscreen ? 18 : 10) {
            ForEach(skills) { skill in
                HStack(spacing: 8) {
                    Image(systemName: skill.icon).font(.system(size: isFullscreen ? 20 : 13)).foregroundColor(skill.color).frame(width: isFullscreen ? 32 : 22)
                    Text(skill.name).font(.system(size: isFullscreen ? 14 : 11, weight: .semibold, design: .monospaced)).foregroundColor(.white).frame(width: isFullscreen ? 90 : 56, alignment: .leading)
                    GeometryReader { barGeo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08))
                            Capsule().fill(LinearGradient(colors: [skill.color, skill.color.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
                                .frame(width: barGeo.size.width * skill.level)
                        }
                    }.frame(height: isFullscreen ? 8 : 5)
                    Text("\(Int(skill.level * 100))%").font(.system(size: isFullscreen ? 12 : 9, weight: .bold, design: .monospaced)).foregroundColor(skill.color).frame(width: 30)
                }
            }
            Divider().background(Color.white.opacity(0.1))
            HStack(spacing: 5) {
                Circle().fill(Color.green).frame(width: 5, height: 5)
                Text("system active — all modules loaded").font(.system(size: 8, weight: .medium, design: .monospaced)).foregroundColor(.green.opacity(0.6))
            }
        }.padding(isFullscreen ? 28 : 14)
    }

    // MARK: - Projects

    private func projectsContent(isFullscreen: Bool) -> some View {
        VStack(spacing: isFullscreen ? 14 : 8) {
            ForEach(projects) { project in
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(LinearGradient(colors: project.gradient.map { $0.opacity(0.25) }, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: isFullscreen ? 48 : 32, height: isFullscreen ? 48 : 32)
                        Image(systemName: project.icon).font(.system(size: isFullscreen ? 20 : 13))
                            .foregroundStyle(LinearGradient(colors: project.gradient, startPoint: .top, endPoint: .bottom))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.title).font(.system(size: isFullscreen ? 14 : 11, weight: .bold, design: .rounded)).foregroundColor(.white)
                        Text(project.description).font(.system(size: isFullscreen ? 12 : 9, weight: .regular, design: .rounded)).foregroundColor(.white.opacity(0.55)).lineLimit(isFullscreen ? 4 : 2)
                    }
                    Spacer()
                }
                .padding(isFullscreen ? 12 : 7)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 0.5)))
            }
        }.padding(isFullscreen ? 24 : 12)
    }

    // MARK: - Connect

    private func connectContent(isFullscreen: Bool) -> some View {
        VStack(spacing: isFullscreen ? 18 : 12) {
            let links: [(String, String, [Color], String)] = [
                ("envelope.fill", "Email", [.blue, .cyan], "mnitish1705@gmail.com"),
                ("chevron.left.forwardslash.chevron.right", "GitHub", [.purple, .pink], "github.com/nitish1705"),
                ("number", "LeetCode", [.orange, .yellow], "leetcode.com/u/Nitish_17_M"),
            ]
            ForEach(links, id: \.1) { icon, label, colors, detail in
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(LinearGradient(colors: colors.map { $0.opacity(0.2) }, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: isFullscreen ? 44 : 32, height: isFullscreen ? 44 : 32)
                            .overlay(Circle().stroke(LinearGradient(colors: colors.map { $0.opacity(0.4) }, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.8))
                        Image(systemName: icon).font(.system(size: isFullscreen ? 18 : 13))
                            .foregroundStyle(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(label).font(.system(size: isFullscreen ? 14 : 11, weight: .semibold, design: .rounded)).foregroundColor(.white)
                        Text(detail).font(.system(size: isFullscreen ? 11 : 9, weight: .regular, design: .monospaced)).foregroundColor(.white.opacity(0.4))
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.system(size: 9)).foregroundColor(.white.opacity(0.3))
                }
            }
        }.padding(isFullscreen ? 28 : 14)
    }

    // MARK: - Education

    private func educationContent(isFullscreen: Bool) -> some View {
        VStack(alignment: .leading, spacing: isFullscreen ? 18 : 10) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(LinearGradient(colors: [.indigo.opacity(0.3), .blue.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: isFullscreen ? 44 : 32, height: isFullscreen ? 44 : 32)
                    Image(systemName: "graduationcap.fill").font(.system(size: isFullscreen ? 18 : 13)).foregroundColor(.indigo)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bachelor of Engineering").font(.system(size: isFullscreen ? 14 : 11, weight: .bold, design: .rounded)).foregroundColor(.white)
                    Text("St. Joseph's Institute of Technology").font(.system(size: isFullscreen ? 11 : 9, weight: .regular, design: .rounded)).foregroundColor(.white.opacity(0.6))
                    Text("Chennai · 3rd Year · 2023 — 2027").font(.system(size: 8, weight: .medium, design: .monospaced)).foregroundColor(.white.opacity(0.35))
                }
                Spacer()
            }
            Divider().background(Color.white.opacity(0.1))
            VStack(alignment: .leading, spacing: 5) {
                Text("beyond the classroom").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(.indigo.opacity(0.7)).textCase(.uppercase)
                bulletPoint("Building iOS apps outside the syllabus")
                bulletPoint("Solving DSA problems on LeetCode")
                bulletPoint("Exploring SwiftUI animations & layout systems")
            }
            if isFullscreen {
                Divider().background(Color.white.opacity(0.1))
                VStack(alignment: .leading, spacing: 5) {
                    Text("philosophy").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(.indigo.opacity(0.7)).textCase(.uppercase)
                    Text("I believe the best way to learn is to build things that break, fix them, and build again.")
                        .font(.system(size: 12, weight: .regular, design: .rounded)).foregroundColor(.white.opacity(0.6)).lineSpacing(4)
                }
            }
        }.padding(isFullscreen ? 28 : 14)
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Circle().fill(Color.indigo.opacity(0.5)).frame(width: 4, height: 4).padding(.top, 4)
            Text(text).font(.system(size: 10, weight: .regular, design: .rounded)).foregroundColor(.white.opacity(0.65))
        }
    }

    // MARK: - Hobbies

    private func hobbiesContent(isFullscreen: Bool) -> some View {
        VStack(alignment: .leading, spacing: isFullscreen ? 14 : 8) {
            let hobbies: [(String, String, Color, String)] = [
                ("bicycle", "Bike Riding", .orange, "Nothing clears the head like a long ride"),
                ("book.fill", "Reading", .blue, "Sci-fi, tech blogs, and rabbit holes"),
                ("puzzlepiece.fill", "Rubik's Cube", .green, "Still trying to beat my PB"),
                ("figure.run", "Exploring", .purple, "New places, new food, new ideas"),
            ]
            ForEach(hobbies, id: \.1) { icon, name, color, desc in
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous).fill(color.opacity(0.15))
                            .frame(width: isFullscreen ? 38 : 28, height: isFullscreen ? 38 : 28)
                        Image(systemName: icon).font(.system(size: isFullscreen ? 16 : 12)).foregroundColor(color)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(name).font(.system(size: isFullscreen ? 13 : 10, weight: .bold, design: .rounded)).foregroundColor(.white)
                        Text(desc).font(.system(size: isFullscreen ? 11 : 8, weight: .regular, design: .rounded)).foregroundColor(.white.opacity(0.5)).lineLimit(isFullscreen ? 3 : 1)
                    }
                    Spacer()
                }
            }
        }.padding(isFullscreen ? 24 : 12)
    }

    // MARK: - Music

    private func musicContent(isFullscreen: Bool) -> some View {
        VStack(spacing: isFullscreen ? 18 : 10) {
            Image(systemName: "waveform").font(.system(size: isFullscreen ? 36 : 22))
                .foregroundStyle(LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing))
            Text("Music keeps me in the zone.").font(.system(size: isFullscreen ? 15 : 11, weight: .semibold, design: .rounded)).foregroundColor(.white)
            Text("Headphones on, world off. Part of every coding session.")
                .font(.system(size: isFullscreen ? 12 : 9, weight: .regular, design: .rounded)).foregroundColor(.white.opacity(0.6)).multilineTextAlignment(.center)
            Divider().background(Color.white.opacity(0.1))
            HStack(spacing: 10) { genreTag("Lo-fi", color: .pink); genreTag("Hip-hop", color: .purple); genreTag("Indie", color: .orange) }
            if isFullscreen {
                HStack(spacing: 10) { genreTag("Tamil", color: .cyan); genreTag("Rock", color: .red); genreTag("Chill", color: .green) }
            }
        }.padding(isFullscreen ? 28 : 12)
    }

    private func genreTag(_ name: String, color: Color) -> some View {
        Text(name).font(.system(size: 9, weight: .semibold, design: .monospaced)).foregroundColor(color)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.12)).overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 0.5)))
    }

    // MARK: - Chess

    private func chessContent(isFullscreen: Bool) -> some View {
        VStack(spacing: isFullscreen ? 18 : 10) {
            HStack(spacing: 5) {
                Text("♚").font(.system(size: isFullscreen ? 40 : 26))
                Text("♛").font(.system(size: isFullscreen ? 40 : 26)).opacity(0.6)
            }
            Text("Tournament Player").font(.system(size: isFullscreen ? 16 : 12, weight: .bold, design: .rounded)).foregroundColor(.white)
            Text("School chess tournaments. Pattern recognition, thinking ahead — it mirrors coding.")
                .font(.system(size: isFullscreen ? 12 : 9, weight: .regular, design: .rounded)).foregroundColor(.white.opacity(0.6)).multilineTextAlignment(.center)
            Divider().background(Color.white.opacity(0.1))
            HStack(spacing: 14) {
                chessStatBadge(icon: "trophy.fill", label: "Level", value: "School", color: .yellow)
                chessStatBadge(icon: "brain.head.profile", label: "Style", value: "Tactical", color: .orange)
            }
            if isFullscreen {
                HStack(spacing: 14) {
                    chessStatBadge(icon: "clock.fill", label: "Preferred", value: "Rapid", color: .cyan)
                    chessStatBadge(icon: "heart.fill", label: "Opening", value: "King's Indian", color: .red)
                }
            }
        }.padding(isFullscreen ? 28 : 12)
    }

    private func chessStatBadge(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(color)
            Text(value).font(.system(size: 8, weight: .bold, design: .rounded)).foregroundColor(.white.opacity(0.8))
            Text(label).font(.system(size: 7, weight: .medium, design: .monospaced)).foregroundColor(.white.opacity(0.35))
        }.frame(maxWidth: .infinity)
    }

    // MARK: - Gaming

    private func gamingContent(isFullscreen: Bool) -> some View {
        VStack(spacing: isFullscreen ? 18 : 10) {
            Image(systemName: "gamecontroller.fill").font(.system(size: isFullscreen ? 36 : 22))
                .foregroundStyle(LinearGradient(colors: [.green, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
            Text("Casual Gamer").font(.system(size: isFullscreen ? 16 : 12, weight: .bold, design: .rounded)).foregroundColor(.white)
            Text("Not grinding ranked — just enjoying the experience and the stories.")
                .font(.system(size: isFullscreen ? 12 : 9, weight: .regular, design: .rounded)).foregroundColor(.white.opacity(0.6)).multilineTextAlignment(.center)
            if isFullscreen {
                Divider().background(Color.white.opacity(0.1))
                HStack(spacing: 10) {
                    gamingTag("Story-driven", icon: "book.closed.fill", color: .cyan)
                    gamingTag("Open World", icon: "map.fill", color: .green)
                    gamingTag("Co-op", icon: "person.2.fill", color: .orange)
                }
            }
        }.padding(isFullscreen ? 28 : 12)
    }

    private func gamingTag(_ name: String, icon: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(color)
            Text(name).font(.system(size: 8, weight: .semibold, design: .monospaced)).foregroundColor(.white.opacity(0.6))
        }.frame(maxWidth: .infinity).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(color.opacity(0.08)))
    }

    // MARK: - Info

    private func infoContent(isFullscreen: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill").font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                Text("About This Project").font(.system(size: isFullscreen ? 17 : 13, weight: .bold, design: .rounded)).foregroundColor(.white)
                Spacer()
            }
            Divider().background(Color.white.opacity(0.1))
            Text("This project reimagines what a portfolio can be. Designed as a guided interaction — from terminal-inspired typing to a tactile desktop layout representing exploration and discovery.")
                .font(.system(size: isFullscreen ? 13 : 10, weight: .regular, design: .rounded)).foregroundColor(.white.opacity(0.75)).lineSpacing(4)
            Text("Every transition, animation, and layout decision communicates personality through motion and hierarchy. A reflection of my SwiftUI skills and the kind of developer I aspire to become.")
                .font(.system(size: isFullscreen ? 13 : 10, weight: .regular, design: .rounded)).foregroundColor(.white.opacity(0.55)).lineSpacing(4)
            if isFullscreen {
                Divider().background(Color.white.opacity(0.1))
                Text("No external dependencies. No APIs. No internet. Just Swift, SwiftUI, and late nights.")
                    .font(.system(size: 12, weight: .regular, design: .rounded)).foregroundColor(.white.opacity(0.45)).lineSpacing(4)
                Text("Built from scratch for the Apple Swift Student Challenge — designed, coded, and polished within a tight deadline to showcase what's possible with pure SwiftUI.")
                    .font(.system(size: 12, weight: .regular, design: .rounded)).foregroundColor(.white.opacity(0.45)).lineSpacing(4)
                Text("This isn't the final form. The project will continue to evolve — new features, smoother interactions, and deeper content are all on the roadmap.")
                    .font(.system(size: 12, weight: .regular, design: .rounded)).foregroundColor(.white.opacity(0.45)).lineSpacing(4)
            }
            Divider().background(Color.white.opacity(0.1))
            HStack(spacing: 5) {
                Circle().fill(Color.white.opacity(0.3)).frame(width: 4, height: 4)
                Text("v1.0 — Designed & developed by Nitish using SwiftUI")
                    .font(.system(size: 8, weight: .medium, design: .monospaced)).foregroundColor(.white.opacity(0.35))
            }
        }.padding(isFullscreen ? 32 : 14)
    }

    // MARK: - Menu Bar

    private func menuBar(width: CGFloat) -> some View {
        HStack {
            Image(systemName: "apple.logo").font(.system(size: 16)).foregroundColor(.white.opacity(0.8))
            Text("Nitish's Portfolio").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(.white.opacity(0.8))
            Spacer()
            TimelineView(.everyMinute) { context in
                Text(context.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(ZStack { Rectangle().fill(.ultraThinMaterial).environment(\.colorScheme, .dark); Rectangle().fill(Color.black.opacity(0.3)) })
        .overlay(Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5), alignment: .bottom)
    }

    // MARK: - Dock Tooltip (macOS-style bubble above dock)

    private func dockTooltip(for windowID: WindowID) -> some View {
        VStack(spacing: 0) {
            Text(windowID.rawValue)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.black.opacity(0.5))
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    }
                )
        }
    }

    // MARK: - Dock (smart: scrollable when needed, centered when fits)

    private func dockView(screenWidth: CGFloat) -> some View {
        let iconSize: CGFloat = max(28, min(36, screenWidth * 0.085))
        let iconSpacing: CGFloat = iconSize * 0.2
        let dividerTotalWidth: CGFloat = 1.5 + 16
        let hPad: CGFloat = iconSize * 0.4
        let vPad: CGFloat = iconSize * 0.22

        let proCount = CGFloat(WindowID.professionalCases.count)
        let perCount = CGFloat(WindowID.personalCases.count)
        let staCount = CGFloat(WindowID.standaloneCases.count)

        let proW = proCount * iconSize + max(0, proCount - 1) * iconSpacing
        let perW = perCount * iconSize + max(0, perCount - 1) * iconSpacing
        let staW = staCount * iconSize + max(0, staCount - 1) * iconSpacing
        let totalW = proW + perW + staW + dividerTotalWidth * 2 + hPad * 2

        let needsScroll = totalW > screenWidth - 24

        let iconsRow = HStack(spacing: 0) {
            HStack(spacing: iconSpacing) {
                ForEach(WindowID.professionalCases) { wid in dockIcon(windowID: wid, iconSize: iconSize) }
            }
            dockDivider(height: iconSize * 0.85)
            HStack(spacing: iconSpacing) {
                ForEach(WindowID.personalCases) { wid in dockIcon(windowID: wid, iconSize: iconSize) }
            }
            dockDivider(height: iconSize * 0.85)
            HStack(spacing: iconSpacing) {
                ForEach(WindowID.standaloneCases) { wid in dockIcon(windowID: wid, iconSize: iconSize) }
            }
        }
        .padding(.horizontal, hPad)
        .padding(.vertical, vPad)

        let bg = ZStack {
            Capsule().fill(.ultraThinMaterial).environment(\.colorScheme, .dark)
            Capsule().fill(Color.white.opacity(0.06))
            Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.8)
        }

        return Group {
            if needsScroll {
                ScrollView(.horizontal, showsIndicators: false) {
                    iconsRow
                }
                .frame(maxWidth: screenWidth - 24)
                .background(bg)
                .clipShape(Capsule())
            } else {
                iconsRow
                    .background(bg)
            }
        }
        .padding(.bottom, 10)
    }

    private func dockDivider(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color.white.opacity(0.2))
            .frame(width: 1.5, height: height)
            .padding(.horizontal, 8)
    }

    private func dockIcon(windowID: WindowID, iconSize: CGFloat) -> some View {
        let isOpen = windows[windowID]?.isVisible == true && windows[windowID]?.isMinimized != true
        let isHovering = dockHover == windowID

        return VStack(spacing: 2) {
            ZStack {
                RoundedRectangle(cornerRadius: iconSize * 0.25, style: .continuous)
                    .fill(LinearGradient(colors: windowID.accentColors.map { $0.opacity(isOpen ? 0.4 : 0.15) }, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: iconSize, height: iconSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: iconSize * 0.25, style: .continuous)
                            .stroke(LinearGradient(colors: windowID.accentColors.map { $0.opacity(0.5) }, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: isOpen ? 1 : 0.5)
                    )
                Image(systemName: windowID.icon)
                    .font(.system(size: iconSize * 0.42))
                    .foregroundStyle(LinearGradient(colors: windowID.accentColors, startPoint: .top, endPoint: .bottom))
            }
            .scaleEffect(isHovering ? 1.2 : 1.0)
            .offset(y: isHovering ? -4 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)

            Circle().fill(windowID.accentColors[0]).frame(width: 3, height: 3).opacity(isOpen ? 1.0 : 0.0)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                if windows[windowID]?.isMinimized == true {
                    windows[windowID]?.isMinimized = false
                    bringToFront(windowID)
                } else if windows[windowID]?.isVisible == true {
                    windows[windowID]?.isMinimized = true
                } else {
                    let winSize = windowID.defaultSize(for: currentScreenSize)
                    let cx = (currentScreenSize.width - winSize.width) / 2
                    let cy = (currentScreenSize.height - winSize.height) / 2
                    windows[windowID]?.offset = CGSize(width: cx, height: cy)
                    windows[windowID]?.isVisible = true
                    bringToFront(windowID)
                }
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        .onLongPressGesture(minimumDuration: 0.01, pressing: { pressing in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { dockHover = pressing ? windowID : nil }
        }, perform: {})
    }

    private func bringToFront(_ id: WindowID) {
        topZ += 1; windows[id]?.zIndex = topZ
    }

    private var meshBackground: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            if #available(iOS 18.0, *) {
                MeshGradient(width: 3, height: 3,
                    points: [
                        [0, 0], [Float(0.5 + 0.2 * sin(t * 0.7)), 0], [1, 0],
                        [0, Float(0.5 + 0.15 * cos(t * 0.5))], [Float(0.5 + 0.1 * sin(t * 0.9)), Float(0.5 + 0.1 * cos(t * 0.6))], [1, Float(0.5 + 0.15 * sin(t * 0.8))],
                        [0, 1], [Float(0.5 + 0.2 * cos(t * 0.6)), 1], [1, 1],
                    ],
                    colors: [
                        .black, Color(red: 0.05, green: 0.0, blue: 0.15), .black,
                        Color(red: 0.0, green: 0.05, blue: 0.2), Color(red: 0.1, green: 0.0, blue: 0.2), Color(red: 0.0, green: 0.08, blue: 0.15),
                        .black, Color(red: 0.05, green: 0.05, blue: 0.1), .black,
                    ]
                )
            } else {
                LinearGradient(colors: [.black, Color(red: 0.05, green: 0.0, blue: 0.15), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
    }

    // MARK: - Particles

    private func particleLayer(width: CGFloat, height: CGFloat) -> some View {
        Canvas { context, _ in
            for p in particles {
                context.opacity = p.opacity
                context.fill(Circle().path(in: CGRect(x: p.x - p.size / 2, y: p.y - p.size / 2, width: p.size, height: p.size)), with: .color(.white))
            }
        }.allowsHitTesting(false).ignoresSafeArea()
    }

    private func spawnParticle(width: CGFloat, height: CGFloat) {
        guard particles.count < 35 else { return }
        particles.append(HomeParticle(x: .random(in: 0...width), y: height + 10, opacity: .random(in: 0.15...0.5), size: .random(in: 1.5...3.0), speed: .random(in: 0.8...2.5)))
    }

    private func updateParticles() {
        particles = particles.compactMap { p in
            var u = p; u.y -= u.speed; u.opacity -= 0.0008
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

    let fullText = "This project grew out of experimentation.\n It's the result of trying things, breaking them, fixing them, and learning how ideas slowly turn into experiences.\n\nI'm currently exploring Swift and SwiftUI, learning by building rather than waiting to feel ready.\n\nI enjoy the process of figuring things out.\n Watching small design and logic choices change how an app feels.\n\nThis project isn't an endpoint.\nIt's simply a snapshot of where I am right now—curious, learning, and evolving.\n"

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
                try? await Task.sleep(nanoseconds: 8_000_000)
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
                try? await Task.sleep(nanoseconds: 1_000_000)

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

                ScrollView{
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
                try? await Task.sleep(nanoseconds: 8_000_000)
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
                try? await Task.sleep(nanoseconds: 1_000_000)

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

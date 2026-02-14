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

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let atomSize = size * 0.5
            let nucleusSize = atomSize * 0.2
            let electronSize = atomSize * 0.1
            let orbitRadius = atomSize * 0.5

            let buttonWidth = size * 0.3
            let buttonHeight = size * 0.09

            ZStack {
                Color(.black)
                        .ignoresSafeArea()
                VStack(spacing: 60){
                    if !showProfile {
                        ZStack {
                            Circle()
                                .fill(nucleusColor)
                                .frame(width: nucleusSize, height: nucleusSize)
                                .scaleEffect(expandNucleus ? 50.0 : 1.0)

                            Circle()
                                .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                                .frame(width: atomSize, height: atomSize)
                                .opacity(showOrbit ? 1.0 : 0.0)

                            Group {
                                Circle().fill(Color.blue)
                                    .offset(y: -orbitRadius)
                                    .opacity(showBlue ? 1.0 : 0.0)

                                Circle().fill(Color.green)
                                    .offset(y: orbitRadius)
                                    .opacity(showGreen ? 1.0 : 0.0)

                                Circle().fill(Color.red)
                                    .offset(x: orbitRadius)
                                    .opacity(showRed ? 1.0 : 0.0)

                                Circle().fill(Color.yellow)
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
                        .frame(width: buttonWidth, height: buttonHeight)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
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

struct HomePage: View {

    // MARK: - State
    @State private var animateGradient = false
    @State private var selectedCard: Int? = nil
    @State private var showGreeting = false
    @State private var showCards = false
    @State private var showSocials = false
    @State private var profileScale: CGFloat = 0.0
    @State private var cardOffsets: [CGFloat] = [300, 300, 300, 300]
    @State private var floatingOffset: CGFloat = 0
    @State private var glowPhase: CGFloat = 0
    @State private var meshPhase: CGFloat = 0
    @State private var dragOffset: CGSize = .zero
    @State private var particleTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    @State private var particles: [Particle] = []

    // MARK: - Particle model
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var opacity: Double
        var size: CGFloat
        var speed: CGFloat
    }

    // MARK: - Data models
    struct SkillItem: Identifiable {
        let id = UUID()
        let icon: String
        let name: String
        let color: Color
        let level: CGFloat // 0...1
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
        .init(title: "Atom Loader", description: "An atom-inspired animated loading screen with orbital electron paths and sequential transitions.", icon: "atom", gradient: [.cyan, .blue]),
        .init(title: "Portfolio App", description: "This interactive portfolio built entirely in SwiftUI with liquid glass effects and mesh gradients.", icon: "iphone.gen3", gradient: [.purple, .pink]),
        .init(title: "Type Engine", description: "Terminal-style typewriter text engine with haptic feedback and erasure animations.", icon: "keyboard.fill", gradient: [.green, .mint]),
        .init(title: "Experiments", description: "A collection of SwiftUI animation experiments pushing creative boundaries.", icon: "flask.fill", gradient: [.orange, .yellow]),
    ]

    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ZStack {
                // ── Animated Mesh Gradient Background ──
                meshBackground
                    .ignoresSafeArea()

                // ── Floating particles ──
                particleLayer(width: width, height: height)

                // ── Main content ─���
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 40) {

                        // ── Profile header with liquid glass ──
                        profileHeader(width: width)
                            .padding(.top, 60)

                        // ── Greeting text ──
                        if showGreeting {
                            greetingSection(width: width)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(y: 20)),
                                    removal: .opacity
                                ))
                        }

                        // ── Skills section ──
                        if showCards {
                            skillsSection(width: width)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }

                        // ── Projects section ──
                        if showCards {
                            projectsSection(width: width)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }

                        // ── Social links ──
                        if showSocials {
                            socialsSection(width: width)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .onAppear { triggerEntrance() }
            .onReceive(particleTimer) { _ in
                spawnParticle(width: width, height: height)
                updateParticles()
            }
        }
    }
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
                // Fallback on earlier versions
            }
        }
    }

    // MARK: - Particle Layer
    private func particleLayer(width: CGFloat, height: CGFloat) -> some View {
        Canvas { context, size in
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

    // MARK: - Profile Header
    private func profileHeader(width: CGFloat) -> some View {
        VStack(spacing: 16) {
            // Animated avatar ring
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.cyan, .purple, .pink, .orange, .cyan],
                            center: .center
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(animateGradient ? 360 : 0))
                    .blur(radius: 4)
                    .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: animateGradient)

                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.cyan, .purple, .pink, .orange, .cyan],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(animateGradient ? 360 : 0))

                // Avatar placeholder
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.3)],
                            center: .center,
                            startRadius: 5,
                            endRadius: 55
                        )
                    )
                    .frame(width: 110, height: 110)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(
                                LinearGradient(colors: [.white, .cyan.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                            )
                    )
            }
            .scaleEffect(profileScale)
            .offset(y: floatingOffset)

            Text("Nitish")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.white, .cyan], startPoint: .leading, endPoint: .trailing)
                )
                .shadow(color: .cyan.opacity(0.5), radius: 10)

            Text("iOS Developer · Creative Coder · Explorer")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(
            glassCard(cornerRadius: 30)
        )
    }

    // MARK: - Greeting Section
    private func greetingSection(width: CGFloat) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "quote.opening")
                    .foregroundColor(.cyan.opacity(0.6))
                    .font(.title2)
                Spacer()
            }

            Text("I started coding out of curiosity, and along the way it became something I genuinely enjoy. I like exploring unfamiliar ideas, learning from mistakes, and growing through building.")
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(6)
                .multilineTextAlignment(.leading)

            HStack {
                Spacer()
                Image(systemName: "quote.closing")
                    .foregroundColor(.cyan.opacity(0.6))
                    .font(.title2)
            }
        }
        .padding(24)
        .background(
            glassCard(cornerRadius: 24)
        )
    }

    // MARK: - Skills Section
    private func skillsSection(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader(icon: "chart.bar.fill", title: "Skills")

            ForEach(Array(skills.enumerated()), id: \.element.id) { index, skill in
                HStack(spacing: 14) {
                    Image(systemName: skill.icon)
                        .font(.title3)
                        .foregroundColor(skill.color)
                        .frame(width: 36)

                    Text(skill.name)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 70, alignment: .leading)

                    GeometryReader { barGeo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))

                            Capsule()
                                .fill(
                                    LinearGradient(colors: [skill.color, skill.color.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(width: barGeo.size.width * skill.level)
                                .shadow(color: skill.color.opacity(0.5), radius: 6)
                        }
                    }
                    .frame(height: 8)

                    Text("\(Int(skill.level * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(skill.color)
                        .frame(width: 40)
                }
                .offset(x: cardOffsets[index])
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1),
                    value: cardOffsets[index]
                )
            }
        }
        .padding(24)
        .background(
            glassCard(cornerRadius: 24)
        )
        .onAppear {
            for i in cardOffsets.indices {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(Double(i) * 0.12)) {
                    cardOffsets[i] = 0
                }
            }
        }
    }

    // MARK: - Projects Section
    private func projectsSection(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader(icon: "folder.fill", title: "Projects")

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                ForEach(Array(projects.enumerated()), id: \.element.id) { index, project in
                    projectCard(project: project, index: index)
                }
            }
        }
        .padding(24)
        .background(
            glassCard(cornerRadius: 24)
        )
    }

    private func projectCard(project: ProjectItem, index: Int) -> some View {
        let isSelected = selectedCard == index
        return VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(colors: project.gradient.map { $0.opacity(0.3) }, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Image(systemName: project.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(colors: project.gradient, startPoint: .top, endPoint: .bottom)
                    )
            }
            .frame(height: 60)

            Text(project.title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)

            if isSelected {
                Text(project.description)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)

                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: isSelected
                                ? project.gradient.map { $0.opacity(0.8) }
                                : [.white.opacity(0.15), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 1.5 : 0.8
                    )
            }
        )
        .shadow(color: isSelected ? project.gradient[0].opacity(0.3) : .clear, radius: 12)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                if selectedCard == index { selectedCard = nil }
                else { selectedCard = index }
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }

    // MARK: - Socials Section
    private func socialsSection(width: CGFloat) -> some View {
        VStack(spacing: 16) {
            sectionHeader(icon: "link", title: "Connect")

            HStack(spacing: 20) {
                socialButton(icon: "envelope.fill", label: "Email", colors: [.blue, .cyan])
                socialButton(icon: "chevron.left.forwardslash.chevron.right", label: "GitHub", colors: [.purple, .pink])
                socialButton(icon: "network", label: "Web", colors: [.orange, .yellow])
            }
        }
        .padding(24)
        .background(
            glassCard(cornerRadius: 24)
        )
    }

    private func socialButton(icon: String, label: String, colors: [Color]) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: colors.map { $0.opacity(0.25) }, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(colors: colors.map { $0.opacity(0.5) }, startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1
                            )
                    )

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(
                        LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                    )
            }

            Text(label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Reusable Components

    private func glassCard(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.25), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        }
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.cyan)
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Spacer()
        }
    }

    // MARK: - Entrance Animations
    private func triggerEntrance() {
        animateGradient = true

        // Floating effect on avatar
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            floatingOffset = -8
        }

        // Profile scale-in
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
            profileScale = 1.0
        }

        // Greeting fade-in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.7)) {
                showGreeting = true
            }
        }

        // Cards slide-in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeOut(duration: 0.6)) {
                showCards = true
            }
        }

        // Socials
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.6)) {
                showSocials = true
            }
        }
    }

    // MARK: - Particle System
    private func spawnParticle(width: CGFloat, height: CGFloat) {
        guard particles.count < 40 else { return }
        let particle = Particle(
            x: CGFloat.random(in: 0...width),
            y: height + 10,
            opacity: Double.random(in: 0.15...0.5),
            size: CGFloat.random(in: 1.5...3.5),
            speed: CGFloat.random(in: 0.4...1.2)
        )
        particles.append(particle)
    }

    private func updateParticles() {
        particles = particles.compactMap { p in
            var updated = p
            updated.y -= updated.speed
            updated.opacity -= 0.003
            if updated.y < -20 || updated.opacity <= 0 { return nil }
            return updated
        }
    }
}

struct ProfileView2: View{
    @State private var typedText = ""
    @State private var isTextFinished = false
    @State private var nextPage = false
    @State private var isVisible = false
    @State private var showCard = false
    
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    let fullText = "\nI should probably start with an introduction.\n\n Hey, I’m Nitish.\n\nI started coding out of curiosity, and along the way it became something I genuinely enjoy.\n\nI like exploring unfamiliar ideas, learning from mistakes, and growing through building.\n\nI don’t know everything yet, but I’m always ready to learn, experiment, and move forward.\n\nThis project is just one step in that ongoing journey.\n"
    
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
                    nextPage = true
                }
            }
        }
    }
    var body: some View{
        ZStack{
            let buttonWidth = screenWidth * 0.45
            let buttonHeight = screenWidth * 0.12
            Color.black.ignoresSafeArea()
            
            VStack{
                HStack{
                    Text(typedText)
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.green)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 30)
                Spacer()
                if(isTextFinished){
                    Button{
                        nextPage = false
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
                    .onAppear{
                        withAnimation(
                            .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true)
                        ){
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
            
            if(nextPage){
                HomePage()
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }

        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                startTyping()
            }
        }
        
    }
}

struct ProfileView: View {
    @State private var typedText = ""
    @State private var showCard = false
    @State private var dragOffset = CGSize.zero
    @State private var isVisible = false
    @State private var textFinished = false
    @State private var showHome = false

    let fullText = "This project grew out of experimentation.\n It’s the result of trying things, breaking them, fixing them, and learning how ideas slowly turn into experiences.\n\nI’m currently exploring Swift and SwiftUI, learning by building rather than waiting to feel ready.\n\nI enjoy the process of figuring things out.\n Watching small design and logic choices change how an app feels.\n\nEven when I don’t have all the answers, I like moving forward, asking better questions, and improving step by step.\n\nThis project isn’t an endpoint.\nIt’s simply a snapshot of where I am right now—curious, learning, and evolving.\n"
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let buttonWidth = width * 0.45
            let buttonHeight = width * 0.12

            GeometryReader { geo in
                ZStack{
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
                        .padding(.top, geo.safeAreaInsets.top)
                        .frame(width: geo.size.width)
                    }
                    
                    if showHome {
                        ProfileView2()
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                    }
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
                textFinished = false
                withAnimation(.easeInOut(duration: 2)) {
                    showHome = true
                }
            }
        }
    }
}


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

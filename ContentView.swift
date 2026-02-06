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
                nucleusColor = Color(red: 0.1, green: 0.12, blue: 0.18)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showProfile = true
            }
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
                Circle()
                    .fill(nucleusColor)
                    .frame(width: nucleusSize, height: nucleusSize)
                    .scaleEffect(expandNucleus ? 50.0 : 1.0)
                    .offset(y: -100)

                VStack(spacing: 60){
                    if !showProfile {
                        ZStack {
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
    var body: some View{
        VStack{
            Spacer()
            Text("Hey")
                .foregroundStyle(Color.white)
            Spacer()
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

    let fullText = "Hey, I’m Nitish.\n\nI started exploring coding out of curiosity, and somewhere along the way it turned into something I genuinely enjoy.\n\nRight now, I’m diving into Swift and SwiftUI, experimenting, breaking things, fixing them, and learning a little more every day.\n\nI love figuring out how ideas turn into experiences, even if I don’t know all the answers yet.\n\nI’m always ready to learn something new, try unfamiliar things, and grow along the way.\n\nThis project is just one step in that ongoing journey."

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let buttonWidth = width * 0.45
            let buttonHeight = width * 0.12

            VStack(spacing: 30) {

                HStack {
                    Text(typedText)
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .padding(.horizontal, 30)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                
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
                if showHome{
                    HomePage()
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
                Spacer()
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            startTyping()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showCard = true
                }
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
                textFinished = true
            }
        }
    }
    func eraseText() {
        Task {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()

            while true {
                try? await Task.sleep(nanoseconds: 30_000_000)

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
                withAnimation(.easeInOut(duration: 1)) {
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

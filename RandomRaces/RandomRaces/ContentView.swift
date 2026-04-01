import SwiftUI

struct ContentView: View {
    @State private var vm = RaceViewModel()

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width / 600
            switch vm.raceState {
            case .setup:
                SetupView(vm: vm, scale: scale)
            case .idle, .racing, .finished:
                RaceView(vm: vm, scale: scale)
            }
        }
    }
}
//setup
// MARK: - Setup View
struct SetupView: View {
    var vm: RaceViewModel
    var scale: CGFloat

    var body: some View {
        VStack(spacing: 24 * scale) {
            Text("🏇 Horse Race")
                .font(.system(size: 36 * scale, weight: .bold))

            VStack(alignment: .leading, spacing: 8 * scale) {
                Text("Number of horses")
                    .font(.system(size: 18 * scale, weight: .semibold))
                HStack(spacing: 10 * scale) {
                    ForEach(2...8, id: \.self) { n in
                        Button("\(n)") {
                            vm.applyHorseCount(n)
                        }
                        .buttonStyle(.bordered)
                        .font(.system(size: 16 * scale))
                        .background(vm.horseCount == n ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(6)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8 * scale) {
                Text("Horse names")
                    .font(.system(size: 18 * scale, weight: .semibold))
                ForEach(0..<vm.horseCount, id: \.self) { i in
                    HStack {
                        Text(vm.colors[i])
                            .font(.system(size: 20 * scale))
                            .frame(width: 32 * scale)
                        TextField("Horse \(i+1)", text: Binding(
                            get: { i < vm.horseNames.count ? vm.horseNames[i] : "" },
                            set: { if i < vm.horseNames.count { vm.horseNames[i] = $0 } }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 16 * scale))
                    }
                }
            }
            .frame(maxWidth: 360 * scale)

            Button("Go to Starting Gate 🏁") {
                vm.confirmSetup()
            }
            .buttonStyle(.borderedProminent)
            .font(.system(size: 18 * scale, weight: .semibold))
        }
        .padding(32 * scale)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Race View
struct RaceView: View {
    var vm: RaceViewModel
    var scale: CGFloat

    var laneHeight: CGFloat { 64 * scale }

    var body: some View {
        VStack(spacing: 16 * scale) {
            Text("🏇 Horse Race")
                .font(.system(size: 36 * scale, weight: .bold))

            GeometryReader { geo in
                let trackWidth = geo.size.width
                let totalHeight = CGFloat(vm.horses.count) * laneHeight

                ZStack(alignment: .leading) {

                    // --- Grass base ---
                    Canvas { context, size in
                        // Alternating dark/light green lanes
                        for (idx, _) in vm.horses.enumerated() {
                            let y = CGFloat(idx) * laneHeight
                            let baseGreen: Color = idx % 2 == 0
                                ? Color(red: 0.18, green: 0.55, blue: 0.18)
                                : Color(red: 0.14, green: 0.45, blue: 0.14)
                            context.fill(
                                Path(CGRect(x: 0, y: y, width: size.width, height: laneHeight)),
                                with: .color(baseGreen)
                            )
                        }

                        // Grass stripe texture (vertical streaks per lane)
                        for (idx, _) in vm.horses.enumerated() {
                            let y = CGFloat(idx) * laneHeight
                            let stripeColor: Color = idx % 2 == 0
                                ? Color(red: 0.20, green: 0.60, blue: 0.20).opacity(0.4)
                                : Color(red: 0.16, green: 0.50, blue: 0.16).opacity(0.4)
                            var stripeX: CGFloat = 0
                            while stripeX < size.width {
                                context.fill(
                                    Path(CGRect(x: stripeX, y: y, width: 6, height: laneHeight)),
                                    with: .color(stripeColor)
                                )
                                stripeX += 18
                            }
                        }

                        // Horizontal lane dividers
                        for idx in 0...vm.horses.count {
                            let y = CGFloat(idx) * laneHeight
                            let isOuter = idx == 0 || idx == vm.horses.count
                            var line = Path()
                            line.move(to: CGPoint(x: 0, y: y))
                            line.addLine(to: CGPoint(x: size.width, y: y))
                            context.stroke(
                                line,
                                with: .color(Color.white.opacity(isOuter ? 0.7 : 0.35)),
                                lineWidth: isOuter ? 2.5 : 1.2
                            )
                        }

                        // Finish line (red + white dashes)
                        let finishX = size.width - 2
                        var dash = Path()
                        dash.move(to: CGPoint(x: finishX, y: 0))
                        dash.addLine(to: CGPoint(x: finishX, y: totalHeight))
                        context.stroke(dash, with: .color(.red), lineWidth: 3)

                        // Finish line checkerboard dashes
                        let dashH: CGFloat = laneHeight / 4
                        var dy: CGFloat = 0
                        var toggle = true
                        while dy < totalHeight {
                            context.fill(
                                Path(CGRect(x: finishX - 8, y: dy, width: 8, height: dashH)),
                                with: .color(toggle ? .white : .red)
                            )
                            dy += dashH
                            toggle.toggle()
                        }
                    }
                    .frame(width: trackWidth, height: totalHeight)

                    // --- Horse name labels ---
                    VStack(spacing: 0) {
                        ForEach(vm.horses) { horse in
                            HStack {
                                Text(horse.name)
                                    .font(.system(size: 12 * scale, weight: .semibold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
                                    .frame(width: 75 * scale, alignment: .leading)
                                    .padding(.leading, 6)
                                Spacer()
                            }
                            .frame(height: laneHeight)
                        }
                    }

                    // --- Horses ---
                    VStack(spacing: 0) {
                        ForEach(vm.horses) { horse in
                            HStack {
                                Text(horse.color)
                                    .font(.system(size: 30 * scale))
                                    .offset(x: CGFloat(horse.position) * (trackWidth - 80 * scale))
                                    .animation(.linear(duration: 0.05), value: horse.position)
                                Spacer()
                            }
                            .frame(height: laneHeight)
                            .padding(.leading, 80 * scale)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                )
            }
            .frame(height: CGFloat(vm.horses.count) * laneHeight)
            .padding(.horizontal)

            // Results
            if vm.raceState == .finished {
                VStack(alignment: .leading, spacing: 6 * scale) {
                    Text("Results 🏆")
                        .font(.system(size: 20 * scale, weight: .semibold))
                    ForEach(Array(vm.finishOrder.enumerated()), id: \.1.id) { idx, horse in
                        HStack {
                            Text(medal(for: idx)).frame(width: 28 * scale)
                            Text(horse.color)
                                .font(.system(size: 16 * scale))
                            Text(horse.name)
                                .font(.system(size: 16 * scale,
                                              weight: idx == 0 ? .bold : .regular))
                        }
                    }
                }
                .padding(16 * scale)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(10 * scale)
            }

            // Buttons
            HStack(spacing: 12 * scale) {
                if vm.raceState == .idle {
                    Button("Start Race 🏁") { vm.startRace() }
                        .buttonStyle(.borderedProminent)
                        .font(.system(size: 16 * scale, weight: .semibold))
                }
                if vm.raceState == .finished {
                    Button("Race Again") { vm.confirmSetup() }
                        .buttonStyle(.borderedProminent)
                        .font(.system(size: 16 * scale))
                }
                Button("Change Horses") { vm.resetToSetup() }
                    .buttonStyle(.bordered)
                    .font(.system(size: 16 * scale))
            }
            .padding(.bottom, 16 * scale)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 16 * scale)
    }

    func medal(for index: Int) -> String {
        ["🥇","🥈","🥉"][safe: index] ?? "  "
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

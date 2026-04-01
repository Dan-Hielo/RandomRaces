import Foundation
import Observation

@Observable
class RaceViewModel {
    var horses: [Horse] = []
    var raceState: RaceState = .setup
    var tick: Int = 0
    var horseCount: Int = 4
    var horseNames: [String] = ["Thunder", "Blaze", "Storm", "Comet"]

    enum RaceState { case setup, idle, racing, finished }

    private var timer: Timer?

    let colors = Array(repeating: "🏇", count: 8)

    func applyHorseCount(_ count: Int) {
        horseCount = count
        let defaults = ["Thunder","Blaze","Storm","Comet","Rocket","Shadow","Flash","Arrow"]
        while horseNames.count < count {
            horseNames.append(defaults[horseNames.count % defaults.count])
        }
        horseNames = Array(horseNames.prefix(count))
    }

    func startSetup() {
        raceState = .setup
    }

    func confirmSetup() {
        horses = (0..<horseCount).map { i in
            let name = horseNames[i].trimmingCharacters(in: .whitespaces).isEmpty
                ? "Horse \(i+1)" : horseNames[i]
            return Horse(
                name: name,
                color: colors[i],
                baseSpeed: Double.random(in: 0.007...0.013),
                stamina: Double.random(in: 0.6...1.0)
            )
        }
        tick = 0
        raceState = .idle
    }

    func startRace() {
        guard raceState == .idle else { return }
        raceState = .racing
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            self.updatePositions()
        }
    }

    func resetToSetup() {
        timer?.invalidate()
        raceState = .setup
        tick = 0
    }

    private func updatePositions() {
        tick += 1
        let progress = horses.map { $0.position }

        for i in horses.indices {
            guard !horses[i].finished else { continue }

            let p = horses[i].position
            let stamina = horses[i].stamina
            let base = horses[i].baseSpeed

            // Speed phases: burst at start, variation mid-race, fatigue at end
            let startBurst = p < 0.15 ? (1.0 - p / 0.15) * 0.004 : 0.0
            let fatigue = p > 0.7 ? (p - 0.7) / 0.3 * (1.0 - stamina) * 0.006 : 0.0
            let jitter = Double.random(in: -0.003...0.004)
            let packEffect = packDraft(index: i, positions: progress) * 0.002

            horses[i].currentSpeed = max(0.002, base + startBurst - fatigue + jitter + packEffect)
            horses[i].position = min(1.0, p + horses[i].currentSpeed)

            if horses[i].position >= 1.0 {
                horses[i].finished = true
                horses[i].finishTime = tick
            }
        }

        if horses.allSatisfy({ $0.finished }) {
            timer?.invalidate()
            raceState = .finished
        }
    }

    // Slight speed boost when closely behind another horse (drafting)
    private func packDraft(index: Int, positions: [Double]) -> Double {
        let myPos = positions[index]
        let boost = positions.enumerated().filter { $0.offset != index }.reduce(0.0) { acc, other in
            let gap = other.element - myPos
            if gap > 0 && gap < 0.05 { return acc + (0.05 - gap) }
            return acc
        }
        return min(boost, 0.05)
    }

    var finishOrder: [Horse] {
        horses.filter { $0.finished }.sorted { ($0.finishTime ?? 0) < ($1.finishTime ?? 0) }
    }
}

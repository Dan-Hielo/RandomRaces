import Foundation

struct Horse: Identifiable {
    let id = UUID()
    var name: String
    let color: String
    var position: Double = 0.0
    var baseSpeed: Double
    var stamina: Double        // how well they maintain speed
    var currentSpeed: Double = 0.0
    var finished: Bool = false
    var finishTime: Int? = nil
}

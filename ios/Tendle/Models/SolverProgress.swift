import Foundation

struct SolverProgress: Equatable {
    let bestScore: Int
    let expandedStates: Int
    let isFinal: Bool
}

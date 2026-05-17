import SwiftUI

struct GameView: View {
    @State var coordinator: GameCoordinator
    @State private var dragStart: CGPoint?
    @State private var dragCurrent: CGPoint?
    @State private var boardSize: CGSize = .zero
    @State private var lastTick: Date = .now
    @State private var showLoading = true

    private let onFinish: (GameSession) -> Void

    init(coordinator: GameCoordinator, onFinish: @escaping (GameSession) -> Void) {
        self._coordinator = State(initialValue: coordinator)
        self.onFinish = onFinish
    }

    var body: some View {
        VStack(spacing: 16) {
            hud
            boardArea
                .padding(.horizontal)
        }
        .padding(.vertical)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            coordinator.start()
            lastTick = .now
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { showLoading = false }
            }
        }
        .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { now in
            let deltaMs = Int(now.timeIntervalSince(lastTick) * 1000)
            lastTick = now
            coordinator.tick(deltaMs: deltaMs)
            if coordinator.session.phase == .ended {
                onFinish(coordinator.session)
            }
        }
        .overlay(alignment: .center) {
            if showLoading {
                VStack(spacing: 12) {
                    Image("LoadingScene")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                    Text("준비 중…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
    }

    private var hud: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                Text("점수").font(.caption).foregroundStyle(.secondary)
                Text("\(coordinator.session.playerScore)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
            }
            Spacer()
            Image("GameSpider")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .opacity(0.85)
                .accessibilityHidden(true)
            Spacer()
            VStack(alignment: .trailing) {
                Text("남은 시간").font(.caption).foregroundStyle(.secondary)
                Text(timeString(coordinator.session.remainingMs))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
        }
        .padding(.horizontal)
    }

    private func timeString(_ ms: Int) -> String {
        let s = ms / 1000
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    @ViewBuilder
    private var boardArea: some View {
        GeometryReader { geo in
            let cellSize = min(
                geo.size.width / CGFloat(Board.columns),
                geo.size.height / CGFloat(Board.rows)
            )
            let actualW = cellSize * CGFloat(Board.columns)
            let actualH = cellSize * CGFloat(Board.rows)
            let selection = currentSelection(cellSize: cellSize)

            ZStack {
                BoardView(board: coordinator.session.board, highlight: selection, cellSize: cellSize)
                    .frame(width: actualW, height: actualH)
                    .coordinateSpace(name: "board")
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("board"))
                            .onChanged { value in
                                boardSize = CGSize(width: actualW, height: actualH)
                                if dragStart == nil { dragStart = value.startLocation }
                                dragCurrent = value.location
                            }
                            .onEnded { value in
                                boardSize = CGSize(width: actualW, height: actualH)
                                if let sel = selectionFrom(start: value.startLocation,
                                                          end: value.location,
                                                          cellSize: cellSize) {
                                    coordinator.commit(sel)
                                }
                                dragStart = nil
                                dragCurrent = nil
                            }
                    )
                if let selection {
                    let sum = BoardEngine.rectangleSum(selection, on: coordinator.session.board)
                    SelectionOverlay(sum: sum)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func currentSelection(cellSize: CGFloat) -> Selection? {
        guard let start = dragStart, let cur = dragCurrent else { return nil }
        return selectionFrom(start: start, end: cur, cellSize: cellSize)
    }

    private func selectionFrom(start: CGPoint, end: CGPoint, cellSize: CGFloat) -> Selection? {
        guard cellSize > 0 else { return nil }
        let c0 = Int(start.x / cellSize); let r0 = Int(start.y / cellSize)
        let c1 = Int(end.x / cellSize);   let r1 = Int(end.y / cellSize)
        let minC = max(0, min(c0, c1)); let maxC = min(Board.columns - 1, max(c0, c1))
        let minR = max(0, min(r0, r1)); let maxR = min(Board.rows - 1, max(r0, r1))
        guard minC <= maxC && minR <= maxR else { return nil }
        return Selection(minColumn: minC, minRow: minR, maxColumn: maxC, maxRow: maxR)
    }
}

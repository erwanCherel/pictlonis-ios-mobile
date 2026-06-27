import SwiftUI

struct DrawingCanvas: View {
    @ObservedObject var vm: DrawingVM
    @State private var current: [StrokePoint] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white.opacity(0.8)

                // incoming strokes
                ForEach(Array(vm.incomingStrokes.enumerated()), id: \.offset) { _, stroke in
                    Path { path in
                        guard let first = stroke.first else { return }
                        path.move(to: CGPoint(x: first.x, y: first.y))
                        for pt in stroke.dropFirst() {
                            path.addLine(to: CGPoint(x: pt.x, y: pt.y))
                        }
                    }
                    .stroke(Color.blue, lineWidth: 4)
                }

                // current stroke
                Path { path in
                    guard let first = current.first else { return }
                    path.move(to: CGPoint(x: first.x, y: first.y))
                    for pt in current.dropFirst() {
                        path.addLine(to: CGPoint(x: pt.x, y: pt.y))
                    }
                }
                .stroke(Color.purple, lineWidth: 4)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        current.append(.init(x: gesture.location.x, y: gesture.location.y))
                    }
                    .onEnded { _ in
                        if !current.isEmpty {
                            vm.sendStroke(points: current)
                            current.removeAll()
                        }
                    }
            )
        }
    }
}

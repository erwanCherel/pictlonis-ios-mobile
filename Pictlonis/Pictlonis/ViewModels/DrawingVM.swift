import Foundation
import Combine
import FirebaseDatabase
import CoreGraphics


final class DrawingVM: ObservableObject {
let roomId: String
private let ref: DatabaseReference


@Published var incomingStrokes: [[StrokePoint]] = [] // pour rendu


init(roomId: String) {
self.roomId = roomId
self.ref = Database.database().reference().child("rooms").child(roomId).child("strokes")
}


func start() {
ref.observe(.childAdded) { [weak self] snap in
guard let self = self else { return }
// chaque enfant = un stroke { points: [ {x,y}, ... ] }
if let dict = snap.value as? [String: Any],
let arr = dict["points"] as? [[String: Any]] {
let s: [StrokePoint] = arr.compactMap { item in
if let x = item["x"] as? Double, let y = item["y"] as? Double { return .init(x: x, y: y) }
return nil
}
DispatchQueue.main.async { self.incomingStrokes.append(s) }
}
}
}


func stop() { ref.removeAllObservers() }


func sendStroke(points: [StrokePoint]) {
let payload: [String: Any] = [
"points": points.map { ["x": $0.x, "y": $0.y] },
"ts": Date().timeIntervalSince1970
]
ref.childByAutoId().setValue(payload)
}


func clearCanvas() { ref.removeValue() }
}

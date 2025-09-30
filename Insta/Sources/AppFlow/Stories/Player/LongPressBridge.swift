import SwiftUI
import UIKit

struct LongPressBridge: UIViewRepresentable {
    var minimumPressDuration: TimeInterval = 0.2
    var allowableMovement: CGFloat = 80
    var onBegan: () -> Void
    var onEnded: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onBegan: onBegan, onEnded: onEnded)
    }

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.backgroundColor = .clear

        let lp = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handle(_:)))
        lp.minimumPressDuration = minimumPressDuration
        lp.allowableMovement = allowableMovement
        lp.cancelsTouchesInView = false
        lp.delegate = context.coordinator

        v.addGestureRecognizer(lp)
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let onBegan: () -> Void
        let onEnded: () -> Void

        init(onBegan: @escaping () -> Void, onEnded: @escaping () -> Void) {
            self.onBegan = onBegan
            self.onEnded = onEnded
        }

        @objc func handle(_ gr: UILongPressGestureRecognizer) {
            switch gr.state {
            case .began:
                onBegan()
            case .ended, .cancelled, .failed:
                onEnded()
            default:
                break
            }
        }

        // Pozwól rozpoznawać równolegle z innymi gestami (tap/drag)
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}

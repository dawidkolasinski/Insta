import SwiftUI

private struct HoldGestureModifier: ViewModifier {
    let enabled: Bool
    let minHoldDuration: Double
    let cancelDistance: CGFloat
    let onPressDown: () -> Void
    let onHoldStarted: () -> Void
    let onTouchEnded: () -> Void

    @State private var isHolding = false
    @State private var dragExceeded = false
    @State private var hasPressDown = false

    func body(content: Content) -> some View {
        if !enabled {
            content
        } else {
            content
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !hasPressDown {
                                hasPressDown = true
                                onPressDown()
                            }
                            let dx = value.translation.width
                            let dy = value.translation.height
                            if (dx * dx + dy * dy) > (cancelDistance * cancelDistance) {
                                if isHolding {
                                    onTouchEnded()
                                    isHolding = false
                                }
                                dragExceeded = true
                            }
                        }
                        .onEnded { _ in
                            if isHolding || hasPressDown {
                                onTouchEnded()
                                isHolding = false
                                hasPressDown = false
                            }
                            dragExceeded = false
                        }
                )
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: minHoldDuration)
                        .onEnded { success in
                            if success && !dragExceeded {
                                isHolding = true
                                onHoldStarted()
                            }
                        }
                )
        }
    }
}

extension View {
    func holdGesture(
        enabled: Bool = true,
        minHoldDuration: Double,
        cancelDistance: CGFloat,
        onPressDown: @escaping () -> Void,
        onHoldStarted: @escaping () -> Void,
        onTouchEnded: @escaping () -> Void
    ) -> some View {
        self.modifier(
            HoldGestureModifier(
                enabled: enabled,
                minHoldDuration: minHoldDuration,
                cancelDistance: cancelDistance,
                onPressDown: onPressDown,
                onHoldStarted: onHoldStarted,
                onTouchEnded: onTouchEnded
            )
        )
    }
}

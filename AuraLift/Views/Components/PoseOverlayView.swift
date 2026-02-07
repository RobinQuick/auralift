import SwiftUI

/// Draws skeleton connections and joint dots over the camera preview using Canvas.
struct PoseOverlayView: View {
    let poseFrame: PoseFrame?

    var body: some View {
        Canvas { context, size in
            guard let frame = poseFrame else { return }

            // Draw skeleton connections (neon blue lines with glow)
            for connection in SkeletonConnection.skeletonConnections {
                guard let fromKp = frame[connection.from],
                      let toKp = frame[connection.to] else { continue }

                let fromPoint = viewPoint(fromKp.position, in: size)
                let toPoint = viewPoint(toKp.position, in: size)

                var path = Path()
                path.move(to: fromPoint)
                path.addLine(to: toPoint)

                // Glow layer
                context.stroke(
                    path,
                    with: .color(Color.neonBlue.opacity(0.3)),
                    lineWidth: 6
                )
                // Main line
                context.stroke(
                    path,
                    with: .color(Color.neonBlue),
                    lineWidth: 2.5
                )
            }

            // Draw joint dots (cyber orange)
            for (_, keypoint) in frame.keypoints {
                let point = viewPoint(keypoint.position, in: size)

                // Glow circle
                let glowRect = CGRect(
                    x: point.x - 8,
                    y: point.y - 8,
                    width: 16,
                    height: 16
                )
                context.fill(
                    Path(ellipseIn: glowRect),
                    with: .color(Color.cyberOrange.opacity(0.4))
                )

                // Inner dot
                let dotRect = CGRect(
                    x: point.x - 4,
                    y: point.y - 4,
                    width: 8,
                    height: 8
                )
                context.fill(
                    Path(ellipseIn: dotRect),
                    with: .color(Color.cyberOrange)
                )
            }
        }
    }

    /// Converts Vision normalized coordinates to view coordinates.
    /// Vision: (0,0) bottom-left, (1,1) top-right -> View: (0,0) top-left
    private func viewPoint(_ visionPoint: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: visionPoint.x * size.width,
            y: (1 - visionPoint.y) * size.height
        )
    }
}

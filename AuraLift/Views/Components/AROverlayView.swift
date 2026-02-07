import SwiftUI

/// Canvas-based ghost skeleton overlay rendering a semi-transparent neon green
/// dashed skeleton. Visually distinct from the user's solid blue PoseOverlayView.
struct AROverlayView: View {
    let ghostPoseFrame: PoseFrame?
    let config: GhostOverlayConfig

    var body: some View {
        Canvas { context, size in
            guard let frame = ghostPoseFrame else { return }

            // Draw ghost skeleton connections (dashed neon green with glow)
            for connection in SkeletonConnection.skeletonConnections {
                guard let fromKp = frame[connection.from],
                      let toKp = frame[connection.to] else { continue }

                let fromPoint = viewPoint(fromKp.position, in: size)
                let toPoint = viewPoint(toKp.position, in: size)

                var path = Path()
                path.move(to: fromPoint)
                path.addLine(to: toPoint)

                // Subtle glow layer
                context.stroke(
                    path,
                    with: .color(config.lineColor.opacity(config.opacity * 0.4)),
                    lineWidth: config.lineWidth + 4
                )

                // Main dashed line
                context.stroke(
                    path,
                    with: .color(config.lineColor.opacity(config.opacity)),
                    style: StrokeStyle(
                        lineWidth: config.lineWidth,
                        lineCap: .round,
                        dash: [8, 6]
                    )
                )
            }

            // Draw ghost joint dots (smaller than user's orange dots)
            for (_, keypoint) in frame.keypoints {
                let point = viewPoint(keypoint.position, in: size)

                // Glow circle
                let glowRadius = config.dotRadius + 3
                let glowRect = CGRect(
                    x: point.x - glowRadius,
                    y: point.y - glowRadius,
                    width: glowRadius * 2,
                    height: glowRadius * 2
                )
                context.fill(
                    Path(ellipseIn: glowRect),
                    with: .color(config.dotColor.opacity(config.opacity * 0.3))
                )

                // Inner dot
                let dotRect = CGRect(
                    x: point.x - config.dotRadius,
                    y: point.y - config.dotRadius,
                    width: config.dotRadius * 2,
                    height: config.dotRadius * 2
                )
                context.fill(
                    Path(ellipseIn: dotRect),
                    with: .color(config.dotColor.opacity(config.opacity))
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

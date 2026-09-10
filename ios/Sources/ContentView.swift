import SwiftUI

struct ContentView: View {
  @State private var resultText = "Running..."

  var body: some View {
    ScrollView {
      Text(resultText)
        .padding()
        .multilineTextAlignment(.leading)
        .font(.system(.body, design: .monospaced))
    }
    .task {
      do {
        let value = try GuestBridge.callIncrement(41)
        let point = try GuestBridge.callMovePoint(x: 10, y: 20, dx: 3, dy: -5)

        let iterations = 100_000
        let incrementBench = try GuestBridge.benchmarkIncrement(iterations: iterations)
        let movePointBench = try GuestBridge.benchmarkMovePoint(iterations: iterations)

        resultText = """
          increment(41) = \(value)
          move_point(10, 20, 3, -5) = (\(point.x), \(point.y))

          \(format(incrementBench))

          \(format(movePointBench))
          """
      } catch {
        resultText = "Error: \(error)"
      }
    }
  }

  private func format(_ bench: GuestBenchmarkResult) -> String {
    """
    \(bench.label) (\(bench.iterations) calls)
    setup: \(String(format: "%.3f", bench.setupSeconds * 1000)) ms
    total: \(String(format: "%.3f", bench.totalCallSeconds * 1000)) ms
    per call: \(String(format: "%.3f", bench.perCallMicroseconds)) us
    max calls / 60fps frame: \(String(format: "%.0f", bench.maxCallsPerSixtyFpsFrame))
    """
  }
}

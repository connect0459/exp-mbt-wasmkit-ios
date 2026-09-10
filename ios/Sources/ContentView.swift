import SwiftUI

struct ContentView: View {
  @State private var resultText = "Running..."

  var body: some View {
    Text(resultText)
      .padding()
      .multilineTextAlignment(.leading)
      .font(.system(.body, design: .monospaced))
      .task {
        do {
          let value = try GuestBridge.callIncrement(41)
          let iterations = 100_000
          let bench = try GuestBridge.benchmarkIncrement(iterations: iterations)
          resultText = """
            increment(41) = \(value)

            Benchmark (\(iterations) calls)
            setup: \(String(format: "%.3f", bench.setupSeconds * 1000)) ms
            total: \(String(format: "%.3f", bench.totalCallSeconds * 1000)) ms
            per call: \(String(format: "%.3f", bench.perCallMicroseconds)) us
            max calls / 60fps frame: \(String(format: "%.0f", bench.maxCallsPerSixtyFpsFrame))
            """
        } catch {
          resultText = "Error: \(error)"
        }
      }
  }
}

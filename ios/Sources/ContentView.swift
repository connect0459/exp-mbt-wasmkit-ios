import SwiftUI

struct ContentView: View {
  @State private var resultText = "Running..."

  var body: some View {
    Text(resultText)
      .padding()
      .task {
        do {
          let value = try GuestBridge.callIncrement(41)
          resultText = "increment(41) = \(value)"
        } catch {
          resultText = "Error: \(error)"
        }
      }
  }
}

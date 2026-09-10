import Foundation
import WasmKit

enum GuestBridgeError: Error {
  case wasmResourceNotFound
  case exportNotFound(String)
}

struct GuestBenchmarkResult {
  let iterations: Int
  let setupSeconds: Double
  let totalCallSeconds: Double

  var perCallMicroseconds: Double {
    totalCallSeconds / Double(iterations) * 1_000_000
  }

  /// How many calls fit inside a single 60fps frame budget (16.67ms), given
  /// only this call's own cost — ignores everything else a real frame does.
  var maxCallsPerSixtyFpsFrame: Double {
    let frameBudgetSeconds = 1.0 / 60.0
    return frameBudgetSeconds / (totalCallSeconds / Double(iterations))
  }
}

enum GuestBridge {
  private static func loadIncrementFunction() throws -> Function {
    guard let url = Bundle.main.url(forResource: "guest", withExtension: "wasm") else {
      throw GuestBridgeError.wasmResourceNotFound
    }
    let bytes = try [UInt8](Data(contentsOf: url))
    let module = try parseWasm(bytes: bytes)
    let engine = Engine()
    let store = Store(engine: engine)
    let instance = try module.instantiate(store: store)
    guard let increment = instance.exports[function: "increment"] else {
      throw GuestBridgeError.exportNotFound("increment")
    }
    return increment
  }

  static func callIncrement(_ value: UInt32) throws -> UInt32 {
    let increment = try loadIncrementFunction()
    let result = try increment([.i32(value)])
    return result[0].i32
  }

  /// Repeatedly calls the exported increment() function to measure WasmKit's
  /// per-call interpreter overhead, separately from one-time module setup —
  /// this is the load profile question SDL3's game loop would exercise.
  static func benchmarkIncrement(iterations: Int) throws -> GuestBenchmarkResult {
    let setupStart = CFAbsoluteTimeGetCurrent()
    let increment = try loadIncrementFunction()
    let setupSeconds = CFAbsoluteTimeGetCurrent() - setupStart

    var value: UInt32 = 0
    let callStart = CFAbsoluteTimeGetCurrent()
    for _ in 0..<iterations {
      let result = try increment([.i32(value)])
      value = result[0].i32
    }
    let totalCallSeconds = CFAbsoluteTimeGetCurrent() - callStart

    return GuestBenchmarkResult(
      iterations: iterations,
      setupSeconds: setupSeconds,
      totalCallSeconds: totalCallSeconds
    )
  }
}

import Foundation
import WasmKit

enum GuestBridgeError: Error {
  case wasmResourceNotFound
  case exportNotFound(String)
  case memoryExportNotFound
}

struct GuestBenchmarkResult {
  let label: String
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

private struct GuestInstance {
  let instance: Instance
  let memory: Memory

  func function(_ name: String) throws -> Function {
    guard let fn = instance.exports[function: name] else {
      throw GuestBridgeError.exportNotFound(name)
    }
    return fn
  }
}

enum GuestBridge {
  private static func loadInstance() throws -> GuestInstance {
    guard let url = Bundle.main.url(forResource: "guest", withExtension: "wasm") else {
      throw GuestBridgeError.wasmResourceNotFound
    }
    let bytes = try [UInt8](Data(contentsOf: url))
    let module = try parseWasm(bytes: bytes)
    let engine = Engine()
    let store = Store(engine: engine)
    let instance = try module.instantiate(store: store)
    guard let memory = instance.exports[memory: "memory"] else {
      throw GuestBridgeError.memoryExportNotFound
    }
    return GuestInstance(instance: instance, memory: memory)
  }

  static func callIncrement(_ value: UInt32) throws -> UInt32 {
    let guestInstance = try loadInstance()
    let increment = try guestInstance.function("increment")
    let result = try increment([.i32(value)])
    return result[0].i32
  }

  /// move_point(x, y, dx, dy) -> (x', y') takes flat scalar arguments, but
  /// MoonBit boxes the returned tuple on the guest heap and returns a
  /// pointer — so reading the result means reading WasmKit's linear memory,
  /// not just decoding a scalar return value.
  static func callMovePoint(x: Int32, y: Int32, dx: Int32, dy: Int32) throws -> (
    x: Int32, y: Int32
  ) {
    let guestInstance = try loadInstance()
    let movePoint = try guestInstance.function("move_point")
    let result = try movePoint([.i32(UInt32(bitPattern: x)), .i32(UInt32(bitPattern: y)), .i32(UInt32(bitPattern: dx)), .i32(UInt32(bitPattern: dy))])
    let ptr = UInt(result[0].i32)
    return try readPoint(from: guestInstance.memory, at: ptr)
  }

  private static func readPoint(from memory: Memory, at ptr: UInt) throws -> (
    x: Int32, y: Int32
  ) {
    memory.withUnsafeMutableBufferPointer(offset: ptr, count: 8) { buffer in
      let words = buffer.bindMemory(to: Int32.self)
      return (x: words[0], y: words[1])
    }
  }

  /// Repeatedly calls the exported increment() function to measure WasmKit's
  /// per-call interpreter overhead for the cheapest possible call shape
  /// (bare i32 in/out, no allocation).
  static func benchmarkIncrement(iterations: Int) throws -> GuestBenchmarkResult {
    let setupStart = CFAbsoluteTimeGetCurrent()
    let guestInstance = try loadInstance()
    let increment = try guestInstance.function("increment")
    let setupSeconds = CFAbsoluteTimeGetCurrent() - setupStart

    var value: UInt32 = 0
    let callStart = CFAbsoluteTimeGetCurrent()
    for _ in 0..<iterations {
      let result = try increment([.i32(value)])
      value = result[0].i32
    }
    let totalCallSeconds = CFAbsoluteTimeGetCurrent() - callStart

    return GuestBenchmarkResult(
      label: "increment(i32) -> i32",
      iterations: iterations,
      setupSeconds: setupSeconds,
      totalCallSeconds: totalCallSeconds
    )
  }

  /// Repeatedly calls move_point(x, y, dx, dy) -> (x', y'), which additionally
  /// exercises: guest-side heap allocation of the returned tuple, and a
  /// linear-memory read from the host side for every call — the load shape
  /// closer to what an SDL3 call boundary (struct-returning API) would need.
  static func benchmarkMovePoint(iterations: Int) throws -> GuestBenchmarkResult {
    let setupStart = CFAbsoluteTimeGetCurrent()
    let guestInstance = try loadInstance()
    let movePoint = try guestInstance.function("move_point")
    let setupSeconds = CFAbsoluteTimeGetCurrent() - setupStart

    var x: Int32 = 0
    var y: Int32 = 0
    let callStart = CFAbsoluteTimeGetCurrent()
    for _ in 0..<iterations {
      let result = try movePoint([.i32(UInt32(bitPattern: x)), .i32(UInt32(bitPattern: y)), .i32(1), .i32(1)])
      let ptr = UInt(result[0].i32)
      (x, y) = try readPoint(from: guestInstance.memory, at: ptr)
    }
    let totalCallSeconds = CFAbsoluteTimeGetCurrent() - callStart

    return GuestBenchmarkResult(
      label: "move_point(i32 x4) -> boxed tuple + memory read",
      iterations: iterations,
      setupSeconds: setupSeconds,
      totalCallSeconds: totalCallSeconds
    )
  }
}

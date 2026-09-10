import Foundation
import WasmKit

enum GuestBridgeError: Error {
  case wasmResourceNotFound
  case exportNotFound(String)
}

enum GuestBridge {
  static func callIncrement(_ value: UInt32) throws -> UInt32 {
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
    let result = try increment([.i32(value)])
    return result[0].i32
  }
}

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(ObservationMacrosMacros)
import ObservationMacrosMacros

let testMacros: [String: Macro.Type] = [
  "ObservationDerived": ObservationDerived.self,
]
#endif

final class ObservationMacrosTests: XCTestCase {
  func testMacro() throws {
    #if canImport(ObservationMacrosMacros)
    assertMacroExpansion(
      """
      @ObservationDerived private func getX() -> Int { inner.x + 42 }
      """,
      expandedSource:
      """
      private func getX() -> Int {
          self.access(keyPath: \\Self.$_cached_getX)

          if let value = $_cached_getX {
            return value
          }

          let invalidate: @Sendable () -> Void = {
            MainActor.assumeIsolated {
              self.withMutation(keyPath: \\Self.$_cached_getX) {
                self.$_cached_getX = nil
              }
            }
          }

          return withObservationTracking({
            let newValue: Int = { inner.x + 42 }()
            self.withMutation(keyPath: \\Self.$_cached_getX) {
              self.$_cached_getX = newValue
            }
            return newValue
          }, onChange: invalidate)
      }

      private var $_cached_getX: Optional<Int> = nil
      """,
      macros: testMacros
    )
    #else
    throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }
}

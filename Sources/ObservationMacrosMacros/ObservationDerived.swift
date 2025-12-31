import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ObservationDerived: BodyMacro, PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [SwiftSyntax.DeclSyntax] {
    guard let f = declaration.as(FunctionDeclSyntax.self) else {
      fatalError("Not function")
    }

    let cacheName = "$_cached_\(f.name)"

    // If SwiftUI re-renders without reading the underlying value, it
    // will lose the natural data dependency. We have to have retain
    // something to signal SwiftUI that we've changed, so the cached
    // value is itself observable.
    //
    // It would be neat if we could propagate our dependencies (for
    // example, always reading from the underlying value), but the
    // interface we have is a black box. We can't know what is being
    // read without also doing the expensive computation. Something
    // more react like where the dependencies are always read, but the
    // cached value only sometimes computed, would let us avoid this
    // step of observation.
    //
    // ```swift
    // @ObservationDerived(from: inner.x)
    // func getX(_ x: Int) -> Int { x + 42 )
    // ```
    //
    // Expanding to:
    //
    // ```swift
    // let value = withObservationTracking({ inner.x }, onChange: invalidate)
    // if let cachedValue { return cachedValue }
    // cachedValue = body(value)
    // return cachedValue
    // ```
    //
    // In which case the observation of cachedValue is unnecessary.

    // Ideally this would use @ObservationTracked, but it fails in a
    // difficult to debug way. As a quick workaround, we manually
    // inject access and withMutation calls.
    //
    // Thread 0 Crashed::  Dispatch queue: com.apple.main-thread
    // 0   libObservationMacros.dylib             0x10288e08c static ObservationTrackedMacro.expansion<A, B>(of:providingPeersOf:in:) + 700
    return [
      """
      private var \(raw: cacheName): Optional<\(f.signature.returnClause?.type.trimmed)> = nil
      """,
    ]
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
    in context: some MacroExpansionContext
  ) throws -> [CodeBlockItemSyntax] {
    guard let body = declaration.body else {
      fatalError("Missing body")
    }

    guard let f = declaration.as(FunctionDeclSyntax.self) else {
      fatalError("Not function")
    }

    let cacheName = "$_cached_\(f.name)"

    return [
      """
      self.access(keyPath: \\Self.\(raw: cacheName))

      if let value = \(raw: cacheName) {
        return value
      }

      let invalidate: @Sendable () -> Void = {
        MainActor.assumeIsolated {
          self.withMutation(keyPath: \\Self.\(raw: cacheName)) {
            self.\(raw: cacheName) = nil
          }
        }
      }

      return withObservationTracking({
        let newValue: \(f.signature.returnClause?.type.trimmed) = \(body)()
        self.withMutation(keyPath: \\Self.\(raw: cacheName)) {
          self.\(raw: cacheName) = newValue
        }
        return newValue
      }, onChange: invalidate)
      """,
    ]
  }
}

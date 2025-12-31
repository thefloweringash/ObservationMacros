//
//  ObservationMacrosPlugin.swift
//  ObservationMacros
//
//  Created by Andrew Childs on 2025/12/30.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ObservationMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    ObservationDerived.self,
  ]
}

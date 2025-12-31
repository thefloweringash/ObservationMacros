@attached(peer, names: prefixed($_cached_))
@attached(body)
public macro ObservationDerived() = #externalMacro(module: "ObservationMacrosMacros", type: "ObservationDerived")

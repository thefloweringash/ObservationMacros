import Observation
import ObservationMacros
import SwiftUI

@MainActor
@Observable
class Inner {
  var x: Int
  var y: Int

  init(x: Int, y: Int) {
    self.x = x
    self.y = y
  }
}

@MainActor
@Observable
class Test {
  var inner: Inner?

  init(inner: Inner? = nil) {
    self.inner = inner
  }

  @ObservationDerived func getX() -> Int {
    print("Recomputing expensive X value")
    guard let x = inner?.x else { return -1 }
    return x + 1
  }

  @ObservationDerived func getY() -> Int {
    print("Recomputing expensive Y value")
    guard let y = inner?.y else { return -1 }
    return y + 1
  }
}

@main
struct MyApp: App {
  // Hack from https://forums.swift.org/t/is-it-possible-to-developer-a-swiftui-app-using-only-swiftpm/71755
  init() {
    DispatchQueue.main.async {
      NSApp.setActivationPolicy(.regular)
      NSApp.activate(ignoringOtherApps: true)
      NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

struct ContentView: View {
  @State var test = Test(inner: .init(x: 42, y: 142))

  var body: some View {
    let _ = Self._printChanges()
    Text(test.getX().formatted())
    Text(test.getY().formatted())
    Button("Inc X") { test.inner!.x += 1 }
    Button("Inc Y") { test.inner!.y += 1 }
  }
}

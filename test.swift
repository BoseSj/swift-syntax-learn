import Foundation

struct Obj {
  var val: Int { 0 }
}

func dosome(_ something: (Int, Float) -> (String)) {
  something()
}

dosome { num, decinum in
  return "Hello: \(num)"
}
dosome { (num: Int, decinum: Float) in
  return "Hello: \(num)"
}

func hello() {
  print("hello")
}

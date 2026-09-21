import Foundation

struct Obj {
  var val: Int { 0 }
}

func dosome(_ something: (Int, Float) -> (String)) {
  something()
}

dosome { (num: Int, decinum: Float) -> Void in
  return "Hello: \(num)"
}

dosome { num, decinum in
  return "Hello: \(num)"
}


func hello() {
  print("hello")
}

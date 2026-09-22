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
  let val = "Hello: \(num)"
  return val
}


func hello() {
  print("hello")
}

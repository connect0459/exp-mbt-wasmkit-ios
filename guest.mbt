///|
#export_name("increment")
pub fn increment(value : Int) -> Int {
  value + 1
}

///|
#export_name("move_point")
pub fn move_point(x : Int, y : Int, dx : Int, dy : Int) -> (Int, Int) {
  (x + dx, y + dy)
}

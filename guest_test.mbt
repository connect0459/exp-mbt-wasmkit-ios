///|
test "increment returns its argument plus one" {
  assert_eq(increment(41), 42)
}

///|
test "increment handles negative input" {
  assert_eq(increment(-1), 0)
}

///|
test "move_point translates a point by a delta" {
  assert_eq(move_point(10, 20, 3, -5), (13, 15))
}

///|
test "move_point with zero delta returns the original point" {
  assert_eq(move_point(7, -2, 0, 0), (7, -2))
}

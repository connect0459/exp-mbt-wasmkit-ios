///|
test "increment returns its argument plus one" {
  assert_eq(increment(41), 42)
}

///|
test "increment handles negative input" {
  assert_eq(increment(-1), 0)
}

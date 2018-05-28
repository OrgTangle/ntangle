when isMainModule:
  import unittest
  suite "check number equality (failing)":

    test "1 == 0":
      check:
        1 == 0

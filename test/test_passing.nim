when isMainModule:
  import unittest
  suite "check number equality":

    test "1 == 1":
      check:
        1 == 1
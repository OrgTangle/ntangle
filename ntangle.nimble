# Package

version       = "0.1.0"
author        = "Kaushal Modi"
description   = "Basic tangling of Org documents using Nim"
license       = "MIT"
srcDir        = "src"
skipFiles     = @["ntangle_nodbg.nim"]
bin           = @["ntangle"]

# Dependencies

requires "nim >= 0.19.0"

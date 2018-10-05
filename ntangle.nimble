# Package

version       = "0.4.1"
author        = "Kaushal Modi"
description   = "Basic tangling of Org documents using Nim"
license       = "MIT"
srcDir        = "src"
skipFiles     = @["ntangle_nodbg.nim"]
bin           = @["ntangle"]

# Dependencies

requires "nim >= 0.19.0", "cligen >= 0.9.16"

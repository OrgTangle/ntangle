# Package

version       = "0.7.0"
author        = "Kaushal Modi"
description   = "Command-line utility for Tangling of Org mode documents"
license       = "MIT"
srcDir        = "src"
bin           = @["ntangle"]

# Dependencies

requires "nim >= 0.19.6", "cligen >= 0.9.31"

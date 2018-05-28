# Time-stamp: <2018-05-27 23:52:09 kmodi>

import os, strformat, strutils, tables

type
  UserError = object of Exception

var
  fileData = initTable[string, string]()
  outFileName: string
  bufEnabled: bool

proc getFileName(): string =
  ##Get the first command line argument as the file name
  let
    numParams = paramCount()
    params = commandLineParams()

  if numParams == 0:
    raise newException(UserError, "File to be tangled needs to be passed as argument")
  elif numParams >= 1:
    if numParams > 1:
      echo fmt"""WARNING: Only the first argument is used as the file name,
the remaining arguments will be discarded."""
    result = params[0]

proc lineAction(line: string, lnum: int, dir: string) =
  ## On detection of "#+begin_src" with ":tangle foo", enable
  ## recording of LINE, next line onwards to global table ``fileData``.
  ## On detection of "#+end_src", stop that recording.
  let lineParts = line.strip.split(" ")
  if bufEnabled:
    if (lineParts[0].toLowerAscii == "#+end_src"):
      bufEnabled = false
    else:
      try:
        fileData[outFileName].add(line & "\n")
      except KeyError: # If outFileName key is not yet set in fileData
        fileData[outFileName] = line & "\n"
  else:
    if (lineParts[0].toLowerAscii == "#+begin_src"):
      let tangleIndex = lineParts.find(":tangle")
      if tangleIndex >= 2: # Because index 0 would be "#+begin_src", and 1 would be "LANG"
        outFileName = lineParts[tangleIndex + 1]
        if (not outFileName.startsWith "/"): # if relative path
          outFileName = dir / outFileName
        bufEnabled = true

proc writeFiles() =
  ## Write the files from ``fileData``
  for file, data in fileData:
    let data = data.strip(leading=false) # remove trailing newlines/ws at end of data
    echo fmt"Writing {file} ({data.countLines} lines) .."
    writeFile(file, data)

proc doTangle() =
  let
    file = getFileName()
    dir = parentDir(file)
  var lnum = 1
  for line in lines(file):
    lineAction(line, lnum, dir)
    inc lnum
  writeFiles()

proc ntangle() =
  ##NTangle 0.1.0

  try:
    doTangle()
  except:
    stderr.writeLine "Error: " & getCurrentExceptionMsg()
    quit 1

when isMainModule:
  ntangle()

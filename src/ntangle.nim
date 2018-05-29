# Time-stamp: <2018-05-29 11:18:34 kmodi>

import os, strformat, strutils, tables

type
  DebugVerbosity = enum dvNone, dvLow, dvHigh

# const DebugVerbosityLevel = dvLow
const DebugVerbosityLevel = dvNone
template dbg(msg: string, verbosity = dvLow) =
  when DebugVerbosityLevel >= dvLow:
    case DebugVerbosityLevel:
      of dvHigh:
        echo "[DBG] " & fmt(msg)
      of dvLow:
        if verbosity == dvLow:
          echo "[DBG] " & fmt(msg)
      else:                     # This case is never reached
        discard

type
  UserError = object of Exception

const
  tanglePropertiesDefault = {"padline": true}.toTable

var
  orgFile: string
  fileData = initTable[string, string]()
  tangleProperties = tanglePropertiesDefault
  outFileName: string
  bufEnabled: bool
  firstLineSrcBlock = false
  blockIndent = 0

proc getFileName(): string =
  ##Get the first command line argument as the file name
  let
    numParams = paramCount()
    params = commandLineParams()
  dbg "numParams = {numParams}"
  dbg "params = {params}"

  if numParams == 0:
    raise newException(UserError, "File to be tangled needs to be passed as argument")
  elif numParams >= 1:
    if numParams > 1:
      echo """WARNING: Only the first argument is used as the file name,
the remaining arguments will be discarded."""
    result = params[0]

proc parseTangleHeaderArguments(parts: seq[string], lnum: int) =
  let
    args = @["tangle", "padline"]
  # setting defaults
  tangleProperties["padline"] = tanglePropertiesDefault["padline"]
  for arg in args:
    let idx = parts.find(":" & arg)
    dbg "arg={arg}, idx={idx}"
    if idx >= 2: # Because index 0 would be "#+begin_src", and 1 would be "LANG"
      let argval = parts[idx + 1]
      dbg "  argval={argval}"
      case arg:
        of "tangle":
          let
            (dir, basename, _) = splitFile(orgFile)
            lang = parts[1] #Safe to assume that parts[1] will contain the src block LANG, like "nim"
          dbg "Org file = {orgFile}, dir={dir}, base name={basename}"
          var outfile: string = nil
          case argval:
            of "yes":
              outfile = dir / basename & "." & lang
            of "no":
              bufEnabled = false
            else:               #filename
              outfile = argval
              if (not outfile.startsWith "/"): # if relative path
                outfile = dir / outfile
          if (not outfile.isNil):
            outFileName = outfile
            dbg "line {lnum}: buffering enabled for {outFileName}"
            bufEnabled = true
            firstLineSrcBlock = true
        of "padline":
          tangleProperties["padline"] = (not (argval == "no"))

proc lineAdjust(line: string, indent: int): string =
  ## Remove extra indentation from ``line``, and append it with newline.
  result =
    if indent == 0:
      line & "\n"
    elif line.len <= 2 :
      line & "\n"
    else:
      var truncSafe = true
      for i, c in line[0 ..< indent]:
        dbg "line[{i}] = {c}"
        if c != ' ': # Don't truncate if the to-be-truncated portion is not all spaces
          truncSafe = false
          break
      if truncSafe:
        line[indent .. line.high] & "\n"
      else:
        line & "\n"

proc lineAction(line: string, lnum: int) =
  ## On detection of "#+begin_src" with ":tangle foo", enable
  ## recording of LINE, next line onwards to global table ``fileData``.
  ## On detection of "#+end_src", stop that recording.
  let lineParts = line.strip.split(" ")
  if firstLineSrcBlock:
    dbg "  first line of src block"
  if bufEnabled:
    if (lineParts[0].toLowerAscii == "#+end_src"):
      bufEnabled = false
      dbg "line {lnum}: buffering disabled for {outFileName}"
    else:
      dbg "  {lineParts.len} parts: {lineParts}", dvHigh

      # Assume that the first line of every src block has zero
      # indentation.
      if firstLineSrcBlock:
        blockIndent = (line.len - line.strip(trailing=false).len)

      try:
        if firstLineSrcBlock and tangleProperties["padline"]:
          fileData[outFileName].add("\n")
        fileData[outFileName].add(lineAdjust(line, blockIndent))
      except KeyError: # If outFileName key is not yet set in fileData
        fileData[outFileName] = lineAdjust(line, blockIndent)
      dbg "  extra indentation: {blockIndent}"
      firstLineSrcBlock = false
  else:
    if (lineParts[0].toLowerAscii == "#+begin_src"):
      parseTangleHeaderArguments(lineParts, lnum)

proc writeFiles() =
  ## Write the files from ``fileData``
  for file, data in fileData:
    dbg "{file}: <<{data}>>"
    echo fmt"Writing {file} ({data.countLines} lines) .."
    writeFile(file, data)

proc doTangle() =
  orgFile = getFileName()
  dbg "Org file = {orgFile}"
  var lnum = 1
  for line in lines(orgFile):
    dbg "{lnum}: {line}", dvHigh
    lineAction(line, lnum)
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

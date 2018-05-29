# Time-stamp: <2018-05-29 14:11:20 kmodi>

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
  OrgError = object of Exception
  HeaderProperty = object
    padline: bool
    shebang: string

const
  tanglePropertiesDefault = HeaderProperty(padline : true,
                                           shebang : "")

var
  orgFile: string
  fileData = initTable[string, string]() # file, data
  outFileName: string
  currentLang: string
  tangleProperties = initTable[string, HeaderProperty]() # lang, properties
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

proc parseTangleHeaderProperties(hdrArgs: seq[string], lnum: int) =
  ##Org header arguments related to tangling. See (org) Extracting Source Code.
  var prop: HeaderProperty
  try:
    prop = tangleProperties[outFilename]
  except KeyError: #If tangleProperties does not already exist for the current output file
    prop = tanglePropertiesDefault

  for hdrArg in hdrArgs:
    let
      hdrArgParts = hdrArg.strip.split(" ", maxsplit=1)
    if hdrArgParts.len != 2:
      raise newException(OrgError, fmt("Line {lnum} - The header arg ':{hdrArgParts[0]}' is missing its value."))
    let
      arg = hdrArgParts[0]
      argval = hdrArgParts[1].strip(chars={'"'}) #treat :tangle foo.ext and :tangle "foo.ext" the same
    dbg "arg={arg}, argval={argval}"
    case arg:
      of "tangle":
        let (dir, basename, _) = splitFile(orgFile)
        dbg "Org file = {orgFile}, dir={dir}, base name={basename}"
        var outfile: string = nil
        case argval:
          of "yes":
            outfile = dir / basename & "." & currentLang #For now, set the extension = currentLang, works for nim, org, but not everything
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
        case argval:
          of "yes":
            prop.padline = true
          of "no":
            prop.padline = false
          else:
            raise newException(OrgError, fmt("The '{argval}' value for ':{arg}' is invalid. The only valid values are 'yes' and 'no'."))
      of "shebang":
        prop.shebang = argval
      # of "mkdirp":
      #   case argval:
      #     of "yes":
      #       prop.mkdirp = true
      #     of "no":
      #       prop.mkdirp = false
      #     else:
      #       raise newException(OrgError, fmt("The '{argval}' value for ':{arg}' is invalid. The only valid values are 'yes' and 'no'."))
      # of "comments":
      #   case argval:
      #     of "yes":
      #     of "no":
      #     of "link":
      #     of "org":
      #     of "both":
      #     of "noweb":
      #     else:
      #       # error message
      # of "tangle-mode":
      #   # use argval
      # of "no-expand":
      #   case argval:
      #     of "yes":
      #       prop.no-expand = true
      #     of "no":
      #       prop.no-expand = false
      #     else:
      #       raise newException(OrgError, fmt("The '{argval}' value for ':{arg}' is invalid. The only valid values are 'yes' and 'no'."))
      # of "noweb":
      #   case argval:
      #     of "yes":
      #     of "no":
      #     of "tangle":
      #     of "no-export":
      #     of "strip-export":
      #     of "eval":
      #     else:
      #       # error message
      # of "noweb-ref":
      #   # use argval
      # of "noweb-sep":
      #   # use argval
      of "exports", "results":  #Ignore args not relevant to tangling
        discard
      else:
        echo fmt"  [WARN] Line {lnum} - ':{arg}' header argument is not supported at the moment."
        discard
      # of "":
      #   case argval:
      #     of "yes":
      #     of "no":
      #     else:
      #       raise newException(OrgError, fmt("The '{argval}' value for ':{arg}' is invalid. The only valid values are 'yes' and 'no'."))
    tangleProperties[outFilename] = prop #save the updated prop to the global table

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
  let lineParts = line.strip.split(":")
  if firstLineSrcBlock:
    dbg "  first line of src block"
  if bufEnabled:
    if (lineParts[0].toLowerAscii.strip() == "#+end_src"):
      bufEnabled = false
      dbg "line {lnum}: buffering disabled for {outFileName}"
    else:
      dbg "  {lineParts.len} parts: {lineParts}", dvHigh

      # Assume that the first line of every src block has zero
      # indentation.
      if firstLineSrcBlock:
        blockIndent = (line.len - line.strip(trailing=false).len)

      try:
        if firstLineSrcBlock and tangleProperties[outFilename].padline:
          fileData[outFileName].add("\n")
        fileData[outFileName].add(lineAdjust(line, blockIndent))
      except KeyError: # If outFileName key is not yet set in fileData
        fileData[outFileName] = lineAdjust(line, blockIndent)
      dbg "  extra indentation: {blockIndent}"
      firstLineSrcBlock = false
  else:
    let
      firstPart = lineParts[0].toLowerAscii.strip
      firstPartParts = firstPart.split(" ")
    if (firstPartParts[0] == "#+begin_src") and (firstPartParts.len >= 2): #Line needs to begin with "#+begin_src LANG"
      currentLang = firstPartParts[1]
      parseTangleHeaderProperties(lineParts[1 .. lineParts.high], lnum)

proc writeFiles() =
  ## Write the files from ``fileData``
  for file, data in fileData:
    var data_updated = data
    if tangleProperties[file].shebang != "":
      data_updated = tangleProperties[file].shebang & "\n" & data
    dbg "{file}: <<{data_updated}>>"
    echo fmt"  Writing {file} ({data_updated.countLines} lines) .."
    writeFile(file, data_updated)

proc doTangle() =
  orgFile = getFileName()
  echo fmt"Parsing {orgFile} .."
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
    stderr.writeLine "  [ERROR] " & getCurrentExceptionMsg() & "\n"
    quit 1
  finally:
    echo ""

when isMainModule:
  ntangle()

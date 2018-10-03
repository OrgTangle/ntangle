# Time-stamp: <2018-10-03 15:54:17 kmodi>

import os, strformat, strutils, tables

type
  DebugVerbosity = enum dvNone, dvLow, dvHigh

# const DebugVerbosityLevel = dvLow
const DebugVerbosityLevel = dvNone
template dbg(msg: string, verbosity = dvLow) =
  when DebugVerbosityLevel >= dvLow:
    case DebugVerbosityLevel
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
    mkdirp: bool
    permissions: set[FilePermission]

const
  tanglePropertiesDefault = HeaderProperty(padline : true,
                                           shebang : "",
                                           mkdirp : false,
                                           permissions : {})

var
  orgFile: string
  fileData = initTable[string, string]() # file, data
  outFileName: string
  currentLang: string
  tangleProperties = initTable[string, HeaderProperty]() # lang, properties
  bufEnabled: bool
  firstLineSrcBlock = false
  blockIndent = 0

proc parseFilePermissions(octals: string): set[FilePermission] =
  ## Converts the input permissions octal string to a Nim set for FilePermission type.
  # https://devdocs.io/nim/os#FilePermission
  var perm: set[FilePermission]
  let
    readPerms = @[fpUserRead, fpGroupRead, fpOthersRead]
    writePerms = @[fpUserWrite, fpGroupWrite, fpOthersWrite]
    execPerms = @[fpUserExec, fpGroupExec, fpOthersExec]
  for idx, o in octals:
    if o != '0':
      if o in {'4', '5', '6', '7'}:
        perm = perm + {readPerms[idx]}
      if o in {'2', '3', '6', '7'}:
        perm = perm + {writePerms[idx]}
      if o in {'1', '3', '5', '7'}:
        perm = perm + {execPerms[idx]}
  dbg "permissions = {perm}"
  result = perm

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
    case arg
    of "tangle":
      let (dir, basename, _) = splitFile(orgFile)
      dbg "Org file = {orgFile}, dir={dir}, base name={basename}"
      var outfile = ""
      case argval
      of "yes":
        outfile = dir / basename & "." & currentLang #For now, set the extension = currentLang, works for nim, org, but not everything
      of "no":
        bufEnabled = false
      else:               #filename
        outfile = argval
        if (not outfile.startsWith "/"): # if relative path
          outfile = dir / outfile
      if outfile != "":
        outFileName = outfile
        dbg "line {lnum}: buffering enabled for `{outFileName}'"
        bufEnabled = true
        firstLineSrcBlock = true
    of "padline":
      case argval
      of "yes":
        prop.padline = true
      of "no":
        prop.padline = false
      else:
        raise newException(OrgError, fmt("The '{argval}' value for ':{arg}' is invalid. The only valid values are 'yes' and 'no'."))
    of "shebang":
      prop.shebang = argval
    of "mkdirp":
      case argval
      of "yes":
        prop.mkdirp = true
      of "no":
        prop.mkdirp = false
      else:
        raise newException(OrgError, fmt("The '{argval}' value for ':{arg}' is invalid. The only valid values are 'yes' and 'no'."))
    of "tangle-mode":
      let octalPerm = argval.split("#o", maxsplit=1)
      if octalPerm.len != 2:
        raise newException(OrgError, fmt("Line {lnum} - The header arg ':{arg}' has invalid file permissions syntax: {argval}"))
      if octalPerm[1].len < 3:
        raise newException(OrgError, fmt("Line {lnum} - The header arg ':{arg}' has invalid file permissions syntax: {argval}"))
      let
        octalPermOwner = octalPerm[1][0]
        octalPermGroup = octalPerm[1][1]
        octalPermOther = octalPerm[1][2]
      prop.permissions = parseFilePermissions(octalPermOwner & octalPermGroup & octalPermOther)
    # of "comments":
    #   case argval
    #   of "yes":
    #   of "no":
    #   of "link":
    #   of "org":
    #   of "both":
    #   of "noweb":
    #   else:
    #     # error message
    # of "no-expand":
    #   case argval
    #   of "yes":
    #     prop.no-expand = true
    #   of "no":
    #     prop.no-expand = false
    #   else:
    #     raise newException(OrgError, fmt("The '{argval}' value for ':{arg}' is invalid. The only valid values are 'yes' and 'no'."))
    # of "noweb":
    #   case argval
    #   of "yes":
    #   of "no":
    #   of "tangle":
    #   of "no-export":
    #   of "strip-export":
    #   of "eval":
    #   else:
    #     # error message
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
    #   case argval
    #   of "yes":
    #   of "no":
    #   else:
    #     raise newException(OrgError, fmt("The '{argval}' value for ':{arg}' is invalid. The only valid values are 'yes' and 'no'."))
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
      dbg "line {lnum}: buffering disabled for `{outFileName}'"
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
  ## Write the files from ``fileData``.
  for file, data in fileData:
    dbg "  Tangling to `{file}' .."
    let
      (outDir, _, _) = splitFile(file)
    var
      dataUpdated = data
    dbg "  outDir: `{outDir}'"
    if outDir != "":
      if (not dirExists(outDir)) and tangleProperties[file].mkdirp:
        echo fmt"  Creating {outDir} .."
        createDir(outDir)
      if (not dirExists(outDir)):
        raise newException(IOError, fmt"Unable to write to `{file}'; `{outDir}' does not exist")

    if tangleProperties[file].shebang != "":
      dataUpdated = tangleProperties[file].shebang & "\n" & data
      dbg "{file}: <<{dataUpdated}>>"
    echo fmt"  Writing `{file}' ({dataUpdated.countLines} lines) .."
    writeFile(file, dataUpdated)
    if tangleProperties[file].permissions != {}:
      file.setFilePermissions(tangleProperties[file].permissions)
    elif tangleProperties[file].shebang != "":
      # If a tangled file has a shebang, auto-add user executable
      # permissions (as Org does too).
      file.inclFilePermissions({fpUserExec})

proc doTangle(file: string) =
  orgFile = file
  echo fmt"Parsing {orgFile} .."
  var lnum = 1
  for line in lines(orgFile):
    dbg "{lnum}: {line}", dvHigh
    lineAction(line, lnum)
    inc lnum
  writeFiles()

proc ntangle(orgFiles: seq[string]) =
  ## Main
  try:
    if orgFiles.len == 0:
      raise newException(UserError, fmt"Missing the mandatory Org file path. See `ntangle --help'.")
    for f in orgFiles:
      fileData.clear() # Reset the fileData before reading a new Org file
      doTangle(f)
      echo ""
  except:
    stderr.writeLine "  [ERROR] " & getCurrentExceptionMsg() & "\n"
    quit 1

when isMainModule:
  import cligen
  dispatch(ntangle
           , version = ("version", "0.1.1"))

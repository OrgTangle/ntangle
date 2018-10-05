# NTangle - Basic tangling of Org documents
# https://github.com/OrgTangle/ntangle

import os, strformat, strutils, tables, terminal, sequtils

type
  DebugVerbosity = enum dvNone, dvLow, dvHigh

const DebugVerbosityLevel = dvLow
# const DebugVerbosityLevel = dvNone
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
  HeaderArgs = object
    tangle: string
    padline: bool
    shebang: string
    mkdirp: bool
    permissions: set[FilePermission]
  GlobalHeaderArgs = tuple
    lang: string
    args: string
  LevelLangIndex = tuple
    orgLevel: int
    lang: string
  TangleHeaderArgs = Table[LevelLangIndex, HeaderArgs] # orgLevel, lang, header args

func initTangleHeaderArgs(): TangleHeaderArgs = initTable[LevelLangIndex, HeaderArgs]()

var
  orgFile: string
  orgLevel: Natural
  fileData = initTable[string, string]() # file, data
  tangleHeaderArgsDefault = initTangleHeaderArgs()
  outFileName: string
  tangleProperties = initTable[string, HeaderArgs]() # file, header args
  bufEnabled: bool
  firstLineSrcBlock = false
  blockIndent = 0

proc resetTangleHeaderArgsDefault() =
  tangleHeaderArgsDefault.clear()
  # Default tangle header args for all Org levels and languages.
  tangleHeaderArgsDefault[(0, "")] = HeaderArgs(tangle : "no",
                                                padline : true,
                                                shebang : "",
                                                mkdirp : false,
                                                permissions : {})

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

proc parseTangleHeaderProperties(hdrArgs: seq[string], lnum: int, lang: string, onBeginSrc: bool) =
  ## Org header arguments related to tangling. See (org) Extracting Source Code.
  let (dir, basename, _) = splitFile(orgFile)
  dbg "Org file = {orgFile}, dir={dir}, base name={basename}"
  var
    prop: HeaderArgs
    outfile = ""
  if lang != "":
    outfile = dir / basename & "." & lang #For now, set the extension = lang, works for nim, org, but not everything

  try:
    prop = tangleProperties[outFileName]
  except KeyError: #If tangleProperties does not already exist for the current output file
    prop = tangleHeaderArgsDefault[(0, "")]

  for hdrArg in hdrArgs:
    let
      hdrArgParts = hdrArg.strip.split(" ", maxsplit=1)
    if hdrArgParts.len != 2:
      raise newException(OrgError, fmt("Line {lnum} - The header arg ':{hdrArgParts[0]}' is missing its value."))
    let
      arg = hdrArgParts[0]
      argval = hdrArgParts[1].strip(chars={'"'}) #treat :tangle foo.ext and :tangle "foo.ext" the same
    dbg "arg={arg}, argval={argval}, onBeginSrc={onBeginSrc}, outfile={outfile}"
    case arg
    of "tangle":
      prop.tangle = argval
      case argval
      of "yes":
        discard
      of "no":
        bufEnabled = false
      else:               #filename
        outfile = argval
        if (not outfile.startsWith "/"): # if relative path
          outfile = dir / outfile
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
      styledEcho(fgYellow, "  [WARN] ",
                 fgDefault, "Line ",
                 styleBright, $lnum,
                 resetStyle, fmt" - ':{arg}' header argument is not supported at the moment.")
      discard
    # of "":
    #   case argval
    #   of "yes":
    #   of "no":
    #   else:
    #     raise newException(OrgError, fmt("The '{argval}' value for ':{arg}' is invalid. The only valid values are 'yes' and 'no'."))
    # Save the updated prop to the global tables.

    dbg "xx line={lnum}, onBeginSrc={onBeginSrc}, outfile={outfile}"
    if (not onBeginSrc):      # global or subtree property
      tangleHeaderArgsDefault[(orgLevel, lang)] = prop

  if outfile != "":
    outFileName = outfile
    tangleProperties[outFileName] = prop

  dbg "line={lnum}, onBeginSrc={onBeginSrc}, outfile={outfile}"
  if onBeginSrc and (prop.tangle != "no"):
    doAssert outFileName != ""
    dbg "line {lnum}: buffering enabled for `{outFileName}'"
    bufEnabled = true
    firstLineSrcBlock = true

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

proc getOrgLevel(line: string): Natural =
  ## Return the current Org level if ``line`` is an Org heading.
  ## If not on an Org heading, return 0.
  ##
  ## An Org heading has no leading space, and begins with one or more
  ## ``*`` chars, followed by a space, and heading text.
  ##
  ## Examples: "* Heading Level 1", "** Heading Level 2".
  let
    lastStarLocation = line.find("* ")
  if (lastStarLocation >= 0) and
     line[0 .. lastStarLocation].allCharsInSet({'*'}):
    return lastStarLocation + 1

proc lineAction(line: string, lnum: int) =
  ## On detection of "#+begin_src" with ":tangle foo", enable
  ## recording of LINE, next line onwards to global table ``fileData``.
  ## On detection of "#+end_src", stop that recording.
  if line.getOrgLevel() > 0:
    orgLevel = line.getOrgLevel()
    dbg "orgLevel = {orgLevel}"
  let
    lineParts = line.strip.split(":")
    linePartsLower = lineParts.mapIt(it.toLowerAscii.strip())
    orgKeyword = if (lineParts.len >= 3 and
                     linePartsLower[0].startsWith("#+") and
                     (not linePartsLower[0].contains(' '))):
                   linePartsLower[0]
                 else:
                   ""
  if orgKeyword != "":
    dbg "Keyword found on line {lnum}:"
    for i, p in lineParts:
      dbg "  part {i} = {p}"
    if ((orgKeyword == "#+property") and
        (linePartsLower[1].strip() == "header-args")):
      parseTangleHeaderProperties(lineParts[2 .. lineParts.high], lnum, "", false)
  else:
    if firstLineSrcBlock:
      dbg "  first line of src block"
    if bufEnabled:
      if (linePartsLower[0] == "#+end_src"):
        bufEnabled = false
        dbg "line {lnum}: buffering disabled for `{outFileName}'"
      else:
        dbg "  {lineParts.len} parts: {lineParts}", dvHigh

        # Assume that the first line of every src block has zero
        # indentation.
        if firstLineSrcBlock:
          blockIndent = (line.len - line.strip(trailing=false).len)

        try:
          if firstLineSrcBlock and tangleProperties[outFileName].padline:
            fileData[outFileName].add("\n")
          fileData[outFileName].add(lineAdjust(line, blockIndent))
        except KeyError: # If outFileName key is not yet set in fileData
          fileData[outFileName] = lineAdjust(line, blockIndent)
        dbg "  extra indentation: {blockIndent}"
        firstLineSrcBlock = false
    else:
      let
        firstPartParts = linePartsLower[0].split(" ")
      if (firstPartParts[0] == "#+begin_src") and (firstPartParts.len >= 2): #Line needs to begin with "#+begin_src LANG"
        let
          lang = firstPartParts[1]
        parseTangleHeaderProperties(lineParts[1 .. lineParts.high], lnum, lang, true)

proc writeFiles() =
  ## Write the files from ``fileData``.
  dbg "fileData elements: {fileData.len}"
  dbg "fileData: {fileData}"
  if fileData.len == 0:
    echo fmt"  No tangle blocks found"
    return

  for file, data in fileData:
    dbg "  Tangling to `{file}' .."
    let
      (outDir, _, _) = splitFile(file)
    var
      dataUpdated = data
    dbg "  outDir: `{outDir}'"
    if outDir != "":
      if (not dirExists(outDir)) and tangleProperties[file].mkdirp:
        echo fmt"  Creating {outDir}/ .."
        createDir(outDir)
      if (not dirExists(outDir)):
        raise newException(IOError, fmt"Unable to write to `{file}'. `{outDir}/' directory does not exist.")

    if tangleProperties[file].shebang != "":
      dataUpdated = tangleProperties[file].shebang & "\n" & data
      dbg "{file}: <<{dataUpdated}>>"
    styledEcho("  Writing ", fgGreen, file, fgDefault, fmt" ({dataUpdated.countLines} lines) ..")
    writeFile(file, dataUpdated)
    if tangleProperties[file].permissions != {}:
      file.setFilePermissions(tangleProperties[file].permissions)
    elif tangleProperties[file].shebang != "":
      # If a tangled file has a shebang, auto-add user executable
      # permissions (as Org does too).
      file.inclFilePermissions({fpUserExec})

proc doOrgTangle(file: string) =
  ## Tangle Org file ``file``.
  if file.toLowerAscii.endsWith(".org"): # Ignore files with names not ending in ".org"
    # Reset all the tables before reading a new Org file.
    fileData.clear()
    tangleProperties.clear()
    resetTangleHeaderArgsDefault()
    orgFile = file
    styledEcho("Parsing ", styleBright, orgFile, resetStyle, " ..")
    var lnum = 1
    for line in lines(orgFile):
      dbg "{lnum}: {line}", dvHigh
      lineAction(line, lnum)
      inc lnum
    writeFiles()
    echo ""

proc ntangle(orgFilesOrDirs: seq[string]) =
  ## Main
  try:
    for f1 in orgFilesOrDirs:
      let
        f1IsFile = f1.fileExists and (not f1.dirExists)
        f1IsDir = f1.dirExists and (not f1.fileExists)
      dbg "is {f1} a directory? {f1IsDir}"
      dbg "is {f1} a file? {f1IsFile}"
      if f1IsFile:
        doOrgTangle(f1)
      elif f1IsDir:
        styledEcho("Entering directory ", styleBright, f1 / "", resetStyle, " ..")
        for f2 in f1.walkDirRec:
          doOrgTangle(f2)
      else:
        raise newException(UserError, fmt("{f1} is neither a valid file nor a directory"))
  except:
    stderr.styledWriteLine(fgRed, "  [ERROR] ", fgDefault, getCurrentExceptionMsg() & "\n")
    quit 1

when isMainModule:
  import cligen
  dispatchGen(ntangle
              , version = ("version", "0.3.0"))
  if paramCount()==0:
    quit(dispatch_ntangle(@["--help"]))
  else:
    quit(dispatch_ntangle(commandLineParams()))

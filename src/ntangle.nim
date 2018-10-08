# NTangle - Basic tangling of Org documents
# https://github.com/OrgTangle/ntangle

import os, strformat, strutils, tables, terminal, sequtils

type
  DebugVerbosity = enum dvNone, dvLow, dvHigh

# const DebugVerbosityLevel = dvLow
const DebugVerbosityLevel = dvNone
template dbg(msg: string, verbosity = dvLow, prefix = "[DBG] ") =
  when DebugVerbosityLevel >= dvLow:
    case DebugVerbosityLevel
    of dvHigh:
      echo prefix & fmt(msg)
    of dvLow:
      if verbosity == dvLow:
        echo prefix & fmt(msg)
    else:                     # This case is never reached
      discard

const
  tangledExt = {
    "emacs-lisp" : "el",
    "shell" : "sh",
    "bash" : "sh",
    "tcsh" : "csh",
    "rust" : "rs",
    "python" : "py",
    "python3" : "py",
    "ipython" : "py",
    "ipython3" : "py"
  }.toTable
dbg "{tangledExt}"

type
  HeaderArgType = enum
    haPropertyKwd            # #+property: header-args ..
    haPropertyDrawer         # :header-args: ..
    haPropertyDrawerAppend   # :header-args+: ..
    haBeginSrc               # #+begin_src foo ..
    haNone                   # none of the above
  UserError = object of Exception
  OrgError = object of Exception
  HeaderArgs = object
    tangle: string
    padline: bool
    shebang: string
    mkdirp: bool
    permissions: set[FilePermission]
  LangAndArgs = tuple
    argType: HeaderArgType
    lang: string
    args: seq[string]
  LevelLangIndex = tuple
    orgLevel: Natural
    lang: string
  TangleHeaderArgs = Table[LevelLangIndex, HeaderArgs] # orgLevel, lang, header args

func initTangleHeaderArgs(): TangleHeaderArgs = initTable[LevelLangIndex, HeaderArgs]()

var
  orgFile: string
  prevOrgLevel = -1
  orgLevel = 0.Natural
  fileData = initTable[string, string]() # file, data
  headerArgsDefaults = initTangleHeaderArgs()
  outFileName: string
  fileHeaderArgs = initTable[string, HeaderArgs]() # file, header args
  bufEnabled: bool
  firstLineSrcBlock = false
  blockIndent = 0

proc resetStateVars() =
  ## Reset all the state variables.
  ## This is called before reading each new Org file.
  orgFile = ""
  prevOrgLevel = -1
  orgLevel = 0.Natural
  outFileName = ""
  firstLineSrcBlock = false
  blockIndent = 0

  fileData.clear()
  fileHeaderArgs.clear()
  headerArgsDefaults.clear()
  # Default tangle header args for all Org levels and languages.
  headerArgsDefaults[(0.Natural, "")] = HeaderArgs(tangle : "no",
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
  ## ``hdrArgs`` is a sequence like @["KEY1 VAL1", "KEY2 VAL2", ..].
  let
    (dir, basename, _) = splitFile(orgFile)
  dbg "Org file = {orgFile}, dir={dir}, base name={basename}", dvHigh
  dbg("", prefix=" ")           # blank line
  dbg "Line {lnum}, Lang {lang} - hdrArgs: {hdrArgs}"
  var
    hArgs: HeaderArgs
    outfile = ""
  if lang != "":
    let
      langLower = lang.toLowerAscii()
      ext = if tangledExt.hasKey(langLower):
              tangledExt[langLower]
            else:
              lang
    outfile = dir / basename & "." & ext

  if headerArgsDefaults.hasKey((orgLevel, lang)):
    hArgs = headerArgsDefaults[(orgLevel, lang)]
    dbg "Line {lnum} - Using Org level {orgLevel} + lang {lang} scope, now hArgs = {hArgs}"
  else:
    hArgs = headerArgsDefaults[(orgLevel, "")]
    dbg "Line {lnum} - Using only Org level {orgLevel} scope, now hArgs = {hArgs}"

  # If hArgs already specifies the tangled file path, use that!
  if hArgs.tangle != "yes" and
     hArgs.tangle != "no":
    dbg "** Line {lnum} - Old outfile={outfile}, overriding it to {hArgs.tangle}"
    if (not hArgs.tangle.startsWith "/"): # if relative path
      outfile = dir / hArgs.tangle
    else:
      outfile = hArgs.tangle

  for hdrArg in hdrArgs:
    let
      hdrArgParts = hdrArg.strip.split(" ", maxsplit=1)
      arg = hdrArgParts[0]
      argval = hdrArgParts[1]
    dbg "arg={arg}, argval={argval}, onBeginSrc={onBeginSrc}, outfile={outfile}"
    case arg
    of "tangle":
      hArgs.tangle = argval
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
        hArgs.padline = true
      of "no":
        hArgs.padline = false
      else:
        raise newException(OrgError, fmt("The '{argval}' value for ':{arg}' is invalid. The only valid values are 'yes' and 'no'."))
    of "shebang":
      hArgs.shebang = argval
    of "mkdirp":
      case argval
      of "yes":
        hArgs.mkdirp = true
      of "no":
        hArgs.mkdirp = false
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
      hArgs.permissions = parseFilePermissions(octalPermOwner & octalPermGroup & octalPermOther)
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
    #     hArgs.no-expand = true
    #   of "no":
    #     hArgs.no-expand = false
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
    of "comments", "no-expand", "noweb", "noweb-ref", "noweb-sep":
      styledEcho(fgYellow, "  [WARN] ",
                 fgDefault, "Line ",
                 styleBright, $lnum,
                 resetStyle, fmt" - ':{arg}' header argument is not supported at the moment.")
    else:                       # Ignore all other header args
      discard

  # Update the default HeaderArgs for the current orgLevel+lang
  # scope, but only using the header args set using property keyword
  # or the drawer property.
  if (not onBeginSrc):
    dbg "** Line {lnum}: Updating headerArgsDefaults[({orgLevel}, {lang})] to {hArgs}"
    headerArgsDefaults[(orgLevel, lang)] = hArgs

  dbg "[after] Line {lnum} - hArgs = {hArgs}"
  if outfile != "":
    # Save the updated hArgs to the file-specific HeaderArgs global
    # value.
    outFileName = outfile

    dbg "line={lnum}, onBeginSrc={onBeginSrc}, hArgs.tangle={hArgs.tangle} outfile={outfile} | outFileName={outFileName}"
    if onBeginSrc:
      if hArgs.tangle != "no":
        doAssert outFileName != ""
        dbg "line {lnum}: buffering enabled for `{outFileName}'"
        bufEnabled = true
        firstLineSrcBlock = true

    dbg "** Line {lnum}: Updating fileHeaderArgs[{outFileName}] to {hArgs}"
    fileHeaderArgs[outFileName] = hArgs

proc orgRemoveEscapeCommas(line: string): string =
  ## Remove only single leading comma if it's followed by "#+" or "*".
  ## The leading comma can have preceeding spaces too, but it still
  ## should be removed.
  ##
  ## Examples:
  ##   ",#+foo"   ->  "#+foo"
  ##   "  ,#+foo" ->  "  #+foo"
  ##   ",* foo"   ->  "* foo"
  ##   ",,* foo"  ->  ",* foo"
  ##   ",abc"     ->  ",abc"      This comma remains
  ##   ",# abc"   ->  ",# abc"    This comma remains too
  let
    lineParts = line.split(",", maxSplit = 1)
  if (lineParts.len == 2) and
     (lineParts[1].startsWith("#+") or
       lineParts[1].startsWith("*") or
       lineParts[1].startsWith(",")):
      return lineParts[0] & lineParts[1]
  else:
    return line

proc lineAdjust(line: string, indent: int): string =
  ## Remove extra indentation from ``line``, and append it with newline.
  dbg "[lineAdjust] line={line}", dvHigh
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
  result = result.orgRemoveEscapeCommas()

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

proc updateHeaderArgsDefault() =
  ## Update the default header args for the current orgLevel scope.
  # Switch to sibling heading. Example: from "** Heading 4.2" to "** Heading 4.3".
  if prevOrgLevel == orgLevel.int:
    assert orgLevel != 0
    for i in countDown(orgLevel-1, 0):
      if headerArgsDefaults.hasKey((i.Natural, "")):
        headerArgsDefaults[(orgLevel, "")] = headerArgsDefaults[(i.Natural, "")]
        break
  # Switch to child heading. Example: from "** Heading 4.2" to "*** Heading 4.2.1".
  elif prevOrgLevel < orgLevel.int:
    if prevOrgLevel < 0:
      headerArgsDefaults[(orgLevel, "")] = headerArgsDefaults[(0.Natural, "")]
    else:
      headerArgsDefaults[(orgLevel, "")] = headerArgsDefaults[(prevOrgLevel.Natural, "")]
  # Switch to parent heading. Example: from "** Heading 4.2" to "* Heading 5".
  else:
    # Do nothing in this case, because with orgLevel < prevOrgLevel,
    # headerArgsDefaults[(orgLevel.Natural, "")] should already have
    # been populated earlier.
    discard
  prevOrgLevel = orgLevel

proc getHeaderArgs(line: string, lnum: int): LangAndArgs =
  ## Get well-formatted header args.
  ##
  ## Examples:
  ##
  ##   "  #+BEGIN_SRC nim :tangle \"hello.nim\" :flags -d:release  "
  ##   "#+property: header-args:nim :tangle hello.nim :flags -d:release"
  ##   "#+property: HEADER-ARGS :tangle hello.nim :flags -d:release"
  ##   "  :header-args: :tangle hello.nim :flags -d:release"
  ##
  ## All of the above inputs will result in the below string sequence
  ## for the ``args`` field of ``LandAndArgs``:
  ##   -> @["tangle hello.nim", "flags -d:release"]
  ## The ``lang`` field will be an empty string or a language string
  ## like ``"nim"``.
  let
    spaceSepPartsRaw = line.strip.split(" ")
  var
    spaceSepParts: seq[string]
    haType: HeaderArgType = haNone
    headerArgsRaw: seq[string] = @[]
    headerArgs: seq[string] = @[]
    headerArgPair: string
    lang: string
  for p in spaceSepPartsRaw:
    if p.strip() != "":
      spaceSepParts.add(p)
  dbg "spaceSepParts: {spaceSepParts}", dvHigh
  if spaceSepParts.len >= 3 and
     spaceSepParts[0].toLowerAscii() == "#+property:" and
     spaceSepParts[1].toLowerAscii().startsWith("header-args"):
    doAssert spaceSepParts[2][0] == ':',
     fmt"{orgFile}:{lnum} :: {line}" & "\n" &
       "  : The first switch in 'header-args' property must be a key with ':' prefix."
    headerArgsRaw = spaceSepParts[2 .. spaceSepParts.high]
    let
      kwdParts = spaceSepParts[1].split(":")
    if kwdParts.len == 2:
      lang = kwdParts[1].strip()
    haType = haPropertyKwd
  # ":header-args:", ":header-args+:", ":header-args:nim:"
  elif spaceSepParts.len >= 3 and
       spaceSepParts[0].toLowerAscii().startsWith(":header-args"):
    doAssert spaceSepParts[1][0] == ':',
     fmt"{orgFile}:{lnum} :: {line}" & "\n" &
       "  : The first switch in 'header-args' drawer property must be a key with ':' prefix."
    headerArgsRaw = spaceSepParts[1 .. spaceSepParts.high]
    let
      kwdParts = spaceSepParts[0].split(":")
    doAssert kwdParts.len >= 3
    if kwdParts.len == 4:
      lang = kwdParts[2].strip(chars = {' ', '+'})
    if kwdParts[1].strip().endsWith("+"):
      haType = haPropertyDrawerAppend
    else:
      haType = haPropertyDrawer
  elif spaceSepParts.len >= 2 and
       spaceSepParts[0].toLowerAscii() == "#+begin_src":
    if spaceSepParts.len >= 3:
      doAssert spaceSepParts[2][0] == ':'
      headerArgsRaw = spaceSepParts[2 .. spaceSepParts.high]
    lang = spaceSepParts[1].strip()
    haType = haBeginSrc
  if haType != haNone:
    #echo headerArgsRaw
    for i, h in headerArgsRaw:
      if h.len >= 2 and h[0] == ':':
        if i == headerArgsRaw.high:
          raise newException(OrgError, fmt("The header args are ending with a ':key' which is not valid. Found {headerArgsRaw}"))
        if headerArgPair != "":
          headerArgs.add(headerArgPair)
        headerArgPair = h[1 .. h.high]
        #echo fmt"{i} - {headerArgPair}"
      else:
        headerArgPair = headerArgPair & " " & h.strip(chars = {'"'})
        #echo fmt"{i} - {headerArgPair}"
        if i == headerArgsRaw.high:
          headerArgs.add(headerArgPair)
  return (haType, lang, headerArgs)

proc lineAction(line: string, lnum: int) =
  ## On detection of "#+begin_src" with ":tangle foo", enable
  ## recording of LINE, next line onwards to global table ``fileData``.
  ## On detection of "#+end_src", stop that recording.
  if line.getOrgLevel() > 0:
    orgLevel = line.getOrgLevel()
    dbg "orgLevel = {orgLevel}"
    updateHeaderArgsDefault()
  let
    (haType, haLang, haArgs) = getHeaderArgs(line, lnum)
  dbg "[line {lnum}] {line}", dvHigh
  if haType != haNone:
    dbg "getHeaderArgs: line {lnum}:: {haType}, {haLang}, {haArgs}"
  if haType in {haPropertyKwd, haPropertyDrawer, haPropertyDrawerAppend}:
    dbg "Property header-args found [Lang={haLang}]: {haArgs}"
    parseTangleHeaderProperties(haArgs, lnum, haLang, false)
  else:
    let
      lineParts = line.strip.split(":")
      linePartsLower = lineParts.mapIt(it.toLowerAscii.strip())
    if firstLineSrcBlock:
      dbg "  first line of src block"
    dbg "line {lnum}: bufEnabled: {bufEnabled} linePartsLower: {linePartsLower}", dvHigh
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
          assert outFileName != ""
          if firstLineSrcBlock and fileHeaderArgs[outFileName].padline:
            fileData[outFileName].add("\n")
          fileData[outFileName].add(lineAdjust(line, blockIndent))
        except KeyError: # If outFileName key is not yet set in fileData
          fileData[outFileName] = lineAdjust(line, blockIndent)
        dbg "  extra indentation: {blockIndent}"
        firstLineSrcBlock = false
    elif haType == haBeginSrc:
      parseTangleHeaderProperties(haArgs, lnum, haLang, true)

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
      if (not dirExists(outDir)) and fileHeaderArgs[file].mkdirp:
        echo fmt"  Creating {outDir}/ .."
        createDir(outDir)
      if (not dirExists(outDir)):
        raise newException(IOError, fmt"Unable to write to `{file}'. `{outDir}/' directory does not exist.")

    if fileHeaderArgs[file].shebang != "":
      dataUpdated = fileHeaderArgs[file].shebang & "\n" & data
      dbg "{file}: <<{dataUpdated}>>"
    styledEcho("  Writing ", fgGreen, file, fgDefault, fmt" ({dataUpdated.countLines} lines) ..")
    writeFile(file, dataUpdated)
    if fileHeaderArgs[file].permissions != {}:
      file.setFilePermissions(fileHeaderArgs[file].permissions)
    elif fileHeaderArgs[file].shebang != "":
      # If a tangled file has a shebang, auto-add user executable
      # permissions (as Org does too).
      file.inclFilePermissions({fpUserExec})

proc doOrgTangle(file: string) =
  ## Tangle Org file ``file``.
  if file.toLowerAscii.endsWith(".org"): # Ignore files with names not ending in ".org"
    resetStateVars()
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
    stderr.styledWriteLine(fgRed, fmt"  [ERROR] {getCurrentException().name}: ",
                           fgDefault, getCurrentExceptionMsg() & "\n")
    quit 1

when isMainModule:
  import cligen
  dispatchGen(ntangle
              , version = ("version", "0.5.1"))
  if paramCount()==0:
    quit(dispatch_ntangle(@["--help"]))
  else:
    quit(dispatch_ntangle(commandLineParams()))

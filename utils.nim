import macros

proc rec_replace(node, src, dst: NimNode): NimNode {.compileTime.} =
  ## Replace all occurrences of arbitrary src node (possibly complex) with dst node (can be complex)
  if node.kind == src.kind and node == src:
    return dst
  result = copyNimNode(node)
  for n in node:
    result.add(n.rec_replace(src, dst))

proc rec_match_replace(node: NimNode, pairs: openArray[(NimNode, NimNode)]): NimNode {.compileTime.} =
  ## Replace nodes according to the pair mapping
  for (src, dst) in pairs:
    if node.kind == src.kind and node == src:
      return dst
  result = copyNimNode(node)
  for n in node:
    result.add(n.rec_match_replace(pairs))

macro autoConvert*(typ, def: untyped) =
  ## Converts func/proc to a routine that automatically 
  ##   converts its input to the requested type `typ`
  ## Note: typ can also be some arbitrary symbol that will be
  var generic: NimNode
  var args: seq[NimNode]
  result = nnkFuncDef.newNimNode()
  # Find the generic ident and the argnames
  for node in def:
    if node.kind == nnkGenericParams:
      node[0].expectKind nnkIdentDefs
      node[0][0].expectKind nnkIdent
      generic = node[0][0]
    if node.kind == nnkFormalParams:
      ## Argnames go up to the type, which is T
      if node[0].kind == nnkEmpty:
        # Het type args
        for identDef in node[1..^1]:
          identDef.expectKind nnkIdentDefs
          let varDef = identDef[0]
          varDef.expectKind nnkIdent
          if varDef != generic:
            args.add varDef
      else:
        # Flat args
        node[0].expectKind nnkIdent
        let varDefs = node[1]
        varDefs.expectKind nnkIdentDefs
        for varDef in varDefs:
          if varDef.kind == nnkIdent and varDef != generic:
            args.add varDef
    result.add node
  # Construct the body
  var pairs = newSeq[(NimNode, NimNode)]()
  for arg in args:
    pairs.add (arg, newDotExpr(arg, typ))
  var body = copyNimTree(def.body)
  var castBody = body.rec_match_replace(pairs)

  # Construct the result
  result.body = quote do:
    when T is `typ`:
      `body`
    else:
      `castBody`

when isMainModule:
  type Plane* = distinct array[4, float32]
  
  expandMacros:
    func newPlane*[T: SomeNumber](e0, e1, e2, e3: T): Plane {.autoConvert: float32.} =
      [e0, e1, e2, e3].Plane

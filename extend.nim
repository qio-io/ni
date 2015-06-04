import ni
# Example extending Ni with multiline string literal similar to Nim but using
# triple single quotes ''' ... ''' and no skipping whitespace/newline after
# the first delimiter. Its just an example, adding support for """ was harder
# since it intervenes with the existing simple support for normal "strings".
#
# We also add a word "reduce" implemented in Nim. See nitest.nim for some
# trivial tests demonstrating it works by simply importing this module.


#######################################################################
# Extending the Parser with multiline string literals using ''' ... '''
#######################################################################
type
  MultilineStringValueParser = ref object of ValueParser

method parseValue(self: MultilineStringValueParser, s: string): Node {.procvar.} =
  # If it ends and starts with '"""' then ok, no escapes yet
  if s[0..2] == "'''" and s[^3..^1] == "'''":
    result = newValue(s[3..^4])

proc prefixLength(self: MultilineStringValueParser): int = 3

method tokenStart(self: ValueParser, s: string, c: char): bool =
  s == "''" and c == '\''

method tokenReady(self: MultilineStringValueParser, token: string, c: char): string =
  if c == '\'' and token.len > 4 and token[^2..^1] == "''":
    return token & c
  else:
    return nil
    
# This proc does the work extending the Parser instance
proc extendParser(p: Parser) {.procvar.} =
  p.valueParsers.add(MultilineStringValueParser())

## Register our extension proc above in Ni so it gets called
addParserExtension(extendParser)


#######################################################################
# Extending the Interpreter with a Nim primitive word
#######################################################################

proc evalReduce(ni: Interpreter, node: Node): Node =
  ## Evaluate all nodes in the block and return a new block with all results
  ni.stack.add(newActivation(node))
  while not ni.endOfNode:
    ni.args.add(ni.evalNext())
  discard ni.stack.pop
  result = newBlock(ni.args)
  ni.args = @[]

# This is a primitive we want to add
proc primReduce*(ni: Interpreter, a: varargs[Node]): Node =
  ni.evalReduce(a[0])

# This proc does the work extending an Interpreter instance
proc extendInterpreter(ni: Interpreter) {.procvar.} =
  discard ni.root.bindit("reduce", newPrim(primReduce, false, 1))
  
## Register our extension proc in Ni so it gets called
addInterpreterExtension(extendInterpreter)




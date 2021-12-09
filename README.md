# L0

An experimental Fault-Tolerant Parser for the experimental L0 language.
It operates as follows:

- The input text is parsed into a list of blocks.  These are 
strings augmented by an integer which gives the indentation
of a block.

- The list of blocks is transformed to a tree of blocks, where the tree
structure corresponds to the level of indentation.

- An expression parser is mapped over the tree, returning a tree of 
"Expression blocks."  The expression parser operates by first
tokenizing the block content. The tokens are consumed in
by a state machine that operates a stack of tokens that is reduced
to an expression and whenever it is legal to do so.  A reduced
token sequence is an expression that is pushed onto the output 
stream.  An error occurs when the stack is non-empty 
when the end of input occurs. When this happens, an error handling
strategy is invoked.  The result to produce a valid AST in all cases.

It is not hard to design a renderer to take advantage of the 
resulting AST in such way that errors are signaled in an 
unobrusive way, e.g. by indicating a leading bracket that 
has no matching right bracket in red.  The goals in all cases are that

- The full text be always parsed
- Errors be signaled in place in the rendered in a discreet 
and helpful way.

Here is a [demo](https://l0-lab-demo.lamdera.app/).

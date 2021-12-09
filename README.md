# L0

An experimental Fault-Tolerant Parser for the experimental L0 language.
A fragment of the language:

```
Pythagoras, [i a cool dude indeed], says that $a^2 + b^2 = c^2$.
Nonetheless, he didn't know about code:

|| code
factorial n = if n == 0 
  then 1 
  else n * (factorial (n - 1))

These days, every high-school student knows that 

$$
\int_0^1 x^n dx = \frac{1}{n+1}

| indent
The lack of a trailing "$$" is intentional.

```

The example illustrates the main features: inline elements of
the form

```
    [function-name arguments]
```

Thus `[i foo bar]` gives "foo bar" in italics.

These may be nested, a kind of function composition:

```
    [i This is [blue blue sky]]
```

In this example, "This is" is italicized, and "blue sky" is italicized
and rendered in blue.

Verbatim and code blocks of the form

```
    | block-name
    BODY
    
    || verbatim-block-name
    BODY
```

Block names may be followed by arguments, and blocks may be nested
by indenting them. Thus L0 text is represented by a forest of trees.

There are a few exceptions the general pattern
of element + block.  Backticks are used for inline code and single
dollar signs are used for inline math.  As above, an unmatched
"$$" is used for display math.  That's it.  The idea is to have
a convenient and versatile yet minimal language.

## Parser

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

module Data.TestDoc exposing (ex1, text)


ex1 =
    """


| title
TESTS


"""


text_ =
    """
| title 
Test Document

This is a [i real] test.

$a^2 + b^2 = c^2$

|| code
a[0] := 1
"""


text =
    """
| title
L0 Technical Notes

| makeTableOfContents


| defs
[lambda bi x [blue [i x]]]


| heading 1
Introduction

L0 is simple markup language whose syntax is inspired by Lisp.
L0 text consists of ordinary text, [bi elements], and
[bi blocks].  Elements are of the form `[function-name TEXT]`.  Blocks are either ordinary paragraphs or
paragraphs whose first line is of the form `| block-name`
or `|| verbatim-block-name`.  Elements can be composed,
and indentation gives the blocks of L0 text the structure
of a forest of rose trees, that is, `List (Tree a)`.
Like Lisp, L0 has a macro expansion facility,
albeit far simpler.


This document describes the the design of the L0 compiler,
which is implemented in text [link Elm https://elm-lang.org] as a function from source text to Html. See [ilink L0 Examples id-of185-xa448] for
more information on the language.


| heading 1
Compiler: Overview

The compiler is the composite of three functions:

|| code
compiler = parse >> transformST >> render

Here

|| code
L0.parse : String -> SyntaxTree
Acc.transformST : SyntaxTree -> SyntaxTree
Elm.render : SyntaxTree -> Html L0Msg

where

|| code
type alias SyntaxTree = List (Tree ExpressionBlock)

An `ExpressionBlock` is a record somewhat like a `Block` as
described below, except that the content field, instead
of being a string, is of type `Either String (List Expr)`.
If the expression block is derived from a verbatim block,
the content field is of type `Left String`.  If it is an
ordinary block, the content field is of type
`Right (List Expr)`.

| item
[b Parser.] The parser is designed to be "fault-tolerant."  By
this we mean that syntax errors are noted unobtrusivey in place
the rendered text, leaving the remaining text rendered normall.

| item
[b transformST.] The syntax tree is modified so as to provide
a table of contents, number the sections of the doumnent,
resolve cross-refences, expand macro definitions, etc.

| item
[b Render.] This is the easy step.


| heading 1
Parser


The function `L0.parse` is a composite of two functions:


|| code
L0.parse = blocksFromString >> toExpressionBlocks


The first function,

|| code
blocksFromString : String -> List Block

is defined in the module `Tree.BlocksV` of the package
`jxxcarlson/tree-builder`.  It operates a line-processing
state machine to convert the input into a list of blocks
where a block is an ordinary paragraph or block whose
first line is as described above, beginning with the string
`|` or `||`.  A block is a record with fields for the
string content and some auxiliary data such as the indentation
and the line in the source at which the block begins.


The `List Block` value is transformed
into a `List (Tree Expression)`
using `Tree.Build.forestFromBlocks` and  the
helper function

|| code
toExpressionBlock : Block -> ExpressionBlock

This function operates by applying

|| code
Expression.parse : String -> List Expr

to the content field of the given block as well
as to those of its children.


| heading 2
Tokens

The tokenizer converts a string into a list of tokens, where


|| code
type Token
    = LB Meta
    | RB Meta
    | S String Meta
    | W String Meta
    | MathToken Meta
    | CodeToken Meta
    | TokenError (List (DeadEnd Context Problem)) Meta

type alias Meta =
    { begin : Int, end : Int, index: Int }


Here `LB` and `RB` stand for left and right-brackets;
`S` stands for string data, which in practice means "words" (no interior spaces)
and `W` stands for whitespace.  The string [dollarSign] generates a `MathToken`,
while a backtick generates a `CodeToken.`  Thus

|| code
> import Parser.Token exposing(..)
> run "[i foo] $x^2$" |> List.reverse
  [  LB        { begin = 0, end = 0, index = 0   }
   , S "i"     { begin = 1, end = 1, index = 1   }
   , W (" ")   { begin = 2, end = 2, index = 2   }
   , S "foo".  { begin = 3, end = 5, index = 3   }
   , RB        { begin = 6, end = 6, index = 4   }
   , W (" ")   { begin = 7, end = 7, index = 5   }
   , MathToken { begin = 8, end = 8, index = 6   }
   , S "x^2"   { begin = 9, end = 11, index = 7  }
   , MathToken { begin = 12, end = 12, index = 8 }
 ]



The `Meta` components locates
the substring tokenized in the source text and also carries
an index which locates
a given token in a list of tokens.

The `Token.run` function has a companion which gives less
verbose output:

|| code
> import Simple

> Simple.tokenize "[i foo] $x^2$" |> List.reverse
  [LBS,SS "i",WS (" "),SS "foo",RBS,WS (" "),MathTokenS,SS "x^2",MathTokenS]


This is useful for debugging.



| heading 2
From String to Expressions


The idea behind the parser is to first transform the
source text into a list of tokens, then convert the list of
tokens into a list of expressions using
a kind of shift-reduce parser.  The shift-reduce parser is a
functional loop that operates on a value of type `State`, one
field of which is a stack of tokens:

|| code
type alias State =
    { tokens : List Token
    , numberOfTokens : Int
    , tokenIndex : Int
    , committed : List Expr
    , stack : List Token
    }

run : State -> State
run state =
    loop state nextStep


The `nextStep` function operates as follows

| item
Try to get the token at index `state.tokenIndex`; it will be either `Nothing` or `Just token`.

| item
If the return value is `Nothing`, examine the stack. If it is
empty, the loop is complete.  If it is nonempty,
the stack could not be  reduced.  This is an error, so we call `recoverFromError state`.

| item
If the return value is `Just token`, push the token onto the
stack or commit it immediately, depending on the nature of the
token and whether the stack is empty.  Then increment
`state.tokenIndex`, call `reduceStack` and then re-enter the
loop.

Below we describe the tokenizer, the parser, and error recovery. Very briefly, error recovery works by pattern matching on the reversed stack. The push or commit strategy guarantees that the stack begins with a left bracket token, a math token, or a code token. Then we proceed as follows:

| item
If the reversed stack begins with two left brackets, push an
error message onto `stack.committed`, set `state.tokenIndex` to
the token index of the second left bracket, clear the stack,
and re-run the parser on the truncated token list.

| item
If the reversed stack begins with a left bracket followed by a
text token which we take to be a function name, push an error
message onto `state.committed`, set `state.tokenIndex` to the
token index of the function name plus one, clear the stack, and
re-run the parser on the truncated token list.


| item
Etc: a few more patterns, e.g., for code and math.

In other words, when an error is encountered, we make note of the fact in `state.committed` and skip forward in the list of tokens in an attempt to recover from the error.  In this way two properties are guaranteed:


| item
A syntax tree is built based on the full text.

| item
Errors are signaled in the syntax tree and therefore in the rendered text.

| item
Text following an error is not messed up.


The last property is a consequence of the "greediness" of the recovery algorithm.




| heading 2
Expressions

We briefly sketched the operation of the parser in the introduction.  Here we give some more detail.  The functional loop is controlled by the `nextStep` function listed
below.  If retrieving a new token at index `state.tokenIndex` fails, there are two
alternatives. If the stack is empty, then all tokens have been successfully parsed, and the
parse tree stored in `state.committed` represents the full input text.  If the stack
is non-empty, then that is not true, and so an error recovery strategy is invoked.

If  a new token is acquired, it is either converted to an expression and pushed onto `state.committed`, or pushed onto the stack.  Tokens such as those representing a word of source text, are pushed to the stack if the stack is non-empty and are converted and pushed to `state.converted` otherwise.  Tokens such as those representing left and right braces or math and code tokens are always pushed onto the stack.

Once a token is either pushed or committed, the stack is reduced. We describe this
process below.

|| code
run : State -> State
run state =
    loop state nextStep
        |> (\\state_ -> { state_ | committed = List.reverse state_.committed })

nextStep : State -> Step State State
nextStep state =
    case List.Extra.getAt state.tokenIndex state.tokens of
        Nothing ->
            if List.isEmpty state.stack then
                Done state

            else
                recoverFromError state

        Just token ->
            pushToken token { state | tokenIndex = state.tokenIndex + 1 }
                |> reduceState
                |> Loop



| heading 2
Reducibility

To determine reducibility of a list of tokens, that list is first
converted to a list of symbols, where

|| code
type Symbol = L | R | M | C | O


That is, left or right bracket, math or code token, or something else.
Reducibility is a property of the corresponding reversed symbol list:

| item
If the symbol list starts and ends with `M`, it is reducible.

| item
If the symbol list starts and ends with `C`, it is reducible.

| item
If the symbol list starts and ends with `LB`, we apply the
function `reducible`. If the list is empty, return True.  If it
is nonempty, find the first matching `RB`;
delete it and the initial `LB` and apply `reducible` to what
remains.

The first matching `RB` is computed as follows.  Assign a value of +1 to `LB`,
-1 to `RB`, and 0 to `O`.  Then compute cumulative sums of the list of values.
The index of the first cumulative sum to be zero, if it exists, defines the match.

[b Example 1]

|| code
 L,  O,  R,  L,  O,  O,  R
+1,  0, -1, +1,  0,  0, -1
+1, +1,  0, ...


The first `R` is the match.


[b Example 2]


|| code
 L,  O,  L,  O,  O,  O,  R,  R
+1,  0, +1,  0,  0,  0, -1, -1
+1, +1, +2, +2, +2, +2, +1,  0


The last `R` is the match.

| heading 2
Reducing the Stack

Function `reduceState` operates as follows.  It first determines, using function
`Parser.Match.reducible`, whether the stack is reducible.  We describe the algorithm
for this below.  If it is reducible, then the we apply


|| code
eval : List Token -> List Expr

The result of this function application is prepended to `state.committed` and the stack is cleared.  If the stack is not reducible, then the state is passed on unchanged, eventually to be dealt with by the error recovery mechanism.

The `eval` function belies the affinity of L0 with Lisp, albeit at a
far lower level of sophistication.  It operates as follows.  First, the reversed
stack is examined to see if it begins with `LB` token and ends with the `RB` token.
In that case the reversed token list has the form

|| code
  LB _ :: token :: ... args ... :: RB _ :: []


If `token` is of the form `S fName _`, then we can form

|| code
  Expr fName (evalList args)


where `evalList : List Token -> List Expr`.  If the reversed stack does not have the
correct form, then a one-element list of expressions noting an error is returned.

Function `evalList`


[b NOTE:] `eval` and `evalList` call eachother.



| heading 1
Error Recovery


| heading 2
Strategies for blocks


| numbered
[i Make error states unrepresentable.]  It is a
syntax error to omit closing tag of a LaTeX environment is.
The L0 coounter counterpart of a this construct is the
ordinary block.  These have no closing tag, so text
with this type of error is impossible to write.

| numbered
[i Chunk to limit error propagation.] The first stage of
parsing is to chunk the text into blocks.

| heading 2
Strategies for contents of blocks

| numbered
[i Insert error message in committed text and skip ahead.] Example: too many right brackets.







| heading 1
Appendix: Types

| heading 2
SyntaxTree

|| code
type alias SyntaxTree = List (Tree ExpressionBlock)

See `ExpressionBlock` below.

| heading 2
Blocks

From module `Parser.Block`.

|| code
type Block
    = Block
        { name : Maybe String
        , args : List String
        , indent : Int
        , lineNumber : Int
        , numberOfLines : Int
        , blockType : BlockType
        , content : String
        , children : List Block
        }

type BlockType
    = Paragraph
    | OrdinaryBlock (List String)
    | VerbatimBlock (List String)


Paragraphs are the only nameless blocks.  In a block like

|| code
| foo bar baz 21

the block name is "foo" and the arguments are "bar", "baz"
and "21".  [term lineNumber] is the number of the line in
the source text at which the block starts.  This field is
used, for example, to enable a feature in which the user
clicks on the rendered text and the editor jumps to and
highlights the first line of the corresponding block.


| heading 2
Expression Blocks

From module `Parser.Block`.

|| code
{-| -}
type ExpressionBlock
    = ExpressionBlock
        { name : Maybe String
        , args : List String
        , indent : Int
        , lineNumber : Int
        , numberOfLines : Int
        , id : String
        , blockType : BlockType
        , content : Either String (List Expr)
        , children : List ExpressionBlock
        , sourceText : String
        }

|| code
{-| -}
type BlockType
    = Paragraph
    | OrdinaryBlock (List String)
    | VerbatimBlock (List String)


In `ExpressionBlocks`, the content field has been
replaced by the result of applying `Expression.parse`.
In the exampe `| foo bar baz 21`, `args` is the
list `["bar", "baz", "21"]`.  At the moment, the `id` field
is the string version of the line number.  It uniquely
identifies the block and is used as the Html id of the
corresponding rendered element.  The rendered id is used
in a feature whereby the user can search for source text and
have the correspond element (or elements) be highlighted
and brought into focus in the rendered text.  The `sourceText`
field is a copy of the source text from which the
expresssion block has been derived.  Its presence makes it
easy to search the rendered text for the id's which match
a given string of putative source text.

| heading 2
Expr

From module `Parser.Expr`.

|| code
type Expr
    = Expr String (List Expr) Meta
    | Text String Meta
    | Verbatim String String Meta
    | Error String

The `meta` field is the same as the corresponding
meta field for `Parser.Token.Token`.

| heading 2
Token

From module `Parser.Token`.

|| code
type Token
    = LB Meta
    | RB Meta
    | S String Meta
    | W String Meta
    | MathToken Meta
    | CodeToken Meta
    | TokenError (List (DeadEnd Context Problem)) Meta


type alias Meta =
    { begin : Int, end : Int, index : Int }

The `index` field is the index of the token in the list
of tokens produced by the tokenizer.  It is used in
error recovery, e.g. to skip forward on or more tokens
or rewind the tokenizer to an earlier position in the
token list.

[tags krakow]








"""

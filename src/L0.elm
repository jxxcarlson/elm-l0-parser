module L0 exposing
    ( parse
    , SyntaxTree, b, bb
    )

{-| A Parser for the experimental L0 module. See the app folder to see how it is used.
The Render folder in app could have been included with the parser. However, this way
users are free to design their own renderer.

Since this package is still experimental (but needed in various test projects).
The documentation is skimpy.

@docs AST, parse

-}

import Parser.Block
import Parser.BlockUtil
import Tree exposing (Tree)
import Tree.BlocksV
import Tree.Build exposing (Error)


{-| -}
type alias SyntaxTree =
    List (Tree Parser.Block.ExpressionBlock)


isVerbatimLine : String -> Bool
isVerbatimLine str =
    String.left 2 str == "||"


{-| -}
parse : String -> SyntaxTree
parse sourceText =
    sourceText
        |> Tree.BlocksV.fromStringAsParagraphs isVerbatimLine
        |> Tree.Build.forestFromBlocks Parser.BlockUtil.l0Empty Parser.BlockUtil.toExpressionBlock Parser.BlockUtil.toBlock
        |> Result.withDefault []


b =
    Tree.BlocksV.fromStringAsParagraphs isVerbatimLine


bb =
    Tree.BlocksV.fromStringAsParagraphs isVerbatimLine >> Tree.Build.forestFromBlocks Parser.BlockUtil.l0Empty Parser.BlockUtil.toExpressionBlock Parser.BlockUtil.toBlock

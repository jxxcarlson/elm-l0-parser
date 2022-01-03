module DiffTest exposing (..)

import Element exposing (Element)
import Expect exposing (Expectation)
import L0 exposing (parseToIntermediateBlocks)
import Parser.Block exposing (ExpressionBlock, IntermediateBlock)
import Parser.BlockUtil
import Parser.Expr exposing (Expr)
import Render.Block
import Render.Differ as Differ
import Render.DifferentialCompiler as DifferentialCompiler
import Render.Msg exposing (L0Msg)
import Render.Settings
import Test exposing (..)
import Tree


a1 =
    [ 1, 2, 3 ]


b1 =
    [ 1, 10, 3 ]


double =
    \x -> 2 * x


a1x =
    List.map double a1


dR =
    Differ.diff a1 b1


diff1 =
    { commonInitialSegment = [ 1 ]
    , commonTerminalSegment = [ 3 ]
    , middleSegmentInSource = [ 2 ]
    , middleSegmentInTarget = [ 10 ]
    }


t1 =
    """
| Intro

| heading 1
Preliminaries

This [i is a test].
"""


t2 =
    """
| Intro

| heading 1
Preliminaries

This [b is a test].
"""


chunker =
    parseToIntermediateBlocks


parser =
    Tree.map Parser.BlockUtil.toExpressionBlockFromIntermediateBlock


renderer =
    Tree.map (Render.Block.render 0 Render.Settings.defaultSettings)


editRecord1 : DifferentialCompiler.EditRecord (Tree.Tree IntermediateBlock) (Tree.Tree ExpressionBlock) (Tree.Tree (Element L0Msg))
editRecord1 =
    DifferentialCompiler.init chunker parser renderer t1


newEditRecord : DifferentialCompiler.EditRecord (Tree.Tree IntermediateBlock) (Tree.Tree ExpressionBlock) (Tree.Tree (Element L0Msg))
newEditRecord =
    DifferentialCompiler.init chunker parser renderer t2


newRendered : List (Tree.Tree (Element L0Msg))
newRendered =
    newEditRecord.rendered


editRecord2Rendered : List (Tree.Tree (Element L0Msg))
editRecord2Rendered =
    editRecord2.rendered


editRecord2 : DifferentialCompiler.EditRecord (Tree.Tree IntermediateBlock) (Tree.Tree ExpressionBlock) (Tree.Tree (Element L0Msg))
editRecord2 =
    DifferentialCompiler.update chunker parser renderer editRecord1 t2


suite : Test
suite =
    Test.only <|
        describe "Differ"
            [ test "subst" <|
                \_ -> Differ.diff a1 b1 |> Expect.equal diff1
            , test "differentialTransform" <|
                \_ -> Differ.differentialTransform double dR a1x |> Expect.equal [ 2, 20, 6 ]

            --, test "differentialCompiler" <|
            --    \_ -> Expect.equal newRendered editRecord2Rendered
            --
            ---- newEditRecord.rendered editRecord2.rendered
            ]

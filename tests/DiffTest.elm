module DiffTest exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import L0
import Parser.Block exposing (IntermediateBlock)
import Parser.BlockUtil
import Parser.Token as Token
import Test exposing (..)
import Tree exposing (Tree)
import Tree.BlocksV
import Tree.Diff as Diff


diffTest label a b expected =
    test label <|
        \_ ->
            let
                _ =
                    L0.parseToIntermediateBlocks a

                _ =
                    L0.parseToIntermediateBlocks b
            in
            List.map2 Diff.diff (L0.parseToIntermediateBlocks a) (L0.parseToIntermediateBlocks b)
                |> Expect.equal expected


suite : Test
suite =
    Test.only <|
        describe "diff trees"
            [ diffTest "diff1" a1 a2 []
            ]


a1 =
    """
1. Lorem ipsum 

2.[i Non consectetur] 

3. Eu volutpat
"""


a2 =
    """
1. Lorem ipsum 

2.[j Non consectetur] 

3. Eu volutpat
"""

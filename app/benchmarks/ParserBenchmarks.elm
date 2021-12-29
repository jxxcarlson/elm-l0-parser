module ParserBenchmarks exposing (suite)

import Array
import Benchmark exposing (..)
import Diff
import L0
import Parser.BlockUtil
import Render.L0
import Render.Settings
import Tree.BlocksV


suite : Benchmark
suite =
    let
        ast =
            L0.parse ex3

        blocks1 : List Tree.BlocksV.Block
        blocks1 =
            Tree.BlocksV.fromStringAsParagraphs isVerbatimLine ex3

        blocks2 : List Tree.BlocksV.Block
        blocks2 =
            Tree.BlocksV.fromStringAsParagraphs isVerbatimLine ex4
    in
    describe "L0.parse"
        [ --benchmark "ex3" <|
          --  \_ -> L0.parse ex3
          --benchmark "render" <|
          --  \_ -> Render.L0.renderFromAST 0 Render.Settings.defaultSettings ast
          --benchmark "find blocks" <|
          --  \_ -> Tree.BlocksV.fromStringAsParagraphs isVerbatimLine ex3
          --
          benchmark "diff" <|
            \_ -> Diff.diff blocks1 blocks2
        ]


isVerbatimLine : String -> Bool
isVerbatimLine str =
    String.left 2 str == "||"


ex0 =
    """
      This i is a test. I repeat blue italic bold this is a test.
"""


ex1 =
    """
This [i is a test]. I repeat [blue [italic [bold this is a test.]]]
"""


ex2 =
    """
| title
Introduction to Calculus

| heading 1
The integral

| heading 1
The derivative
"""


ex3 =
    """
1. Lorem ipsum [i dolor sit amet], consectetur adipiscing elit, sed do eiusmod tempor
incididunt [i [b ut labore et dolore magna aliqua]. Eu volutpat odio facilisis mauris
sit amet massa vitae tortor. [i Non consectetur] a erat nam at lectus urna duis.
Lacus vestibulum sed arcu non [i [b [blue odio euismod lacinia at.]]] Leo integer malesuada
nunc vel. Morbi tempus iaculis urna id. [blue  Enim] lobortis scelerisque fermentum

2. Lorem ipsum [i dolor sit amet], consectetur adipiscing elit, sed do eiusmod tempor
incididunt [i [b ut labore et dolore magna aliqua]. Eu volutpat odio facilisis mauris
sit amet massa vitae tortor. [i Non consectetur] a erat nam at lectus urna duis.
Lacus vestibulum sed arcu non [i [b [blue odio euismod lacinia at.]]] Leo integer malesuada
nunc vel. Morbi tempus iaculis urna id. [blue  Enim] lobortis scelerisque fermentum

3. Lorem ipsum [i dolor sit amet], consectetur adipiscing elit, sed do eiusmod tempor
incididunt [i [b ut labore et dolore magna aliqua]. Eu volutpat odio facilisis mauris
sit amet massa vitae tortor. [i Non consectetur] a erat nam at lectus urna duis.
Lacus vestibulum sed arcu non [i [b [blue odio euismod lacinia at.]]] Leo integer malesuada
nunc vel. Morbi tempus iaculis urna id. [blue  Enim] lobortis scelerisque fermentum
"""


ex4 =
    """
1. Lorem ipsum [i dolor sit amet], consectetur adipiscing elit, sed do eiusmod tempor
incididunt [i [b ut labore et dolore magna aliqua]. Eu volutpat odio facilisis mauris
sit amet massa vitae tortor. [i Non consectetur] a erat nam at lectus urna duis.
Lacus vestibulum sed arcu non [i [b [blue odio euismod lacinia at.]]] Leo integer malesuada
nunc vel. Morbi tempus iaculis urna id. [blue  Enim] lobortis scelerisque fermentum

2. Lorem ipsum [i dolor sit amet], consectetur adipiscing elit, sed do eiusmod tempor
incididunt [i [b ut labore et dolore magna aliqua]. Eu volutpat odio facilisis mauris
sit amet massa vitae tortor. [j Non consectetur] a erat nam at lectus urna duis.
Lacus vestibulum sed arcu non [i [b [blue odio euismod lacinia at.]]] Leo integer malesuada
nunc vel. Morbi tempus iaculis urna id. [blue  Enim] lobortis scelerisque fermentum

3. Lorem ipsum [i dolor sit amet], consectetur adipiscing elit, sed do eiusmod tempor
incididunt [i [b ut labore et dolore magna aliqua]. Eu volutpat odio facilisis mauris
sit amet massa vitae tortor. [i Non consectetur] a erat nam at lectus urna duis.
Lacus vestibulum sed arcu non [i [b [blue odio euismod lacinia at.]]] Leo integer malesuada
nunc vel. Morbi tempus iaculis urna id. [blue  Enim] lobortis scelerisque fermentum
"""

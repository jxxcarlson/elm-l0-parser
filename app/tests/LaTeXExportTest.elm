module LaTeXExportTest exposing (..)

import Expect exposing (Expectation)
import L0
import Render.LaTeX as LaTeX
import Render.Settings as Settings
import Test exposing (..)


source1 =
    """one two!"""


source2 =
    """
| indent
This is indented.

$$
\\int_0^1 x^n dx
$$
"""


testExport label str =
    test label <|
        \_ -> L0.parse str |> LaTeX.export Settings.defaultSettings |> Expect.equal str


testExportModSpace label str =
    test label <|
        \_ -> L0.parse str |> LaTeX.export Settings.defaultSettings |> String.replace " " "" |> Expect.equal (String.replace " " "" str)


suite : Test
suite =
    describe "Render.LaTeX"
        [ testExportModSpace "export paragraph" "one two!"
        , testExport "code block" "|| code\na[0] = 1!\n5! = 60."
        , testExportModSpace "ordinary block" "| foo!\n5! = 60."
        ]

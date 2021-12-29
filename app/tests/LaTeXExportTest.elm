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


testExport label input output =
    test label <|
        \_ -> L0.parse input |> LaTeX.rawExport Settings.defaultSettings |> Expect.equal output


suite : Test
suite =
    describe "Render.LaTeX"
        [ testExport "plain text" "one two!" "one two!"
        , testExport "simple element" "[italic text]" "\\textit{text}"
        , testExport "composed elements" "[b [i text]]" "\\textbf{\\textit{text}}"
        , testExport "inline math" "$x^2$" "$x^2$"
        , testExport "code" "`a[0]=1`" "\\code{a[0]=1}"
        , testExport "code block" "|| code\na[0] = 1" "\\begin{verbatim}\na[0] = 1\n\\end{verbatim}"
        , testExport "ordinary block" "| indent\nstuff" "\\begin{indent}\nstuff\n\\end{indent}"
        , testExport "heading" "| heading 1\nIntro" "\\section{Intro}"
        ]

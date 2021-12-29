module DiffTest exposing (..)

import Dict exposing (Dict)
import Differ
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Parser.Expr exposing (Expr(..))
import Parser.Expression as Expression
import Parser.Simple as Simple exposing (ExprS(..))
import Render.LaTeX
import Render.Lambda as Lambda exposing (Lambda)
import Render.Settings
import Render.Text as Text
import Test exposing (..)


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


suite : Test
suite =
    Test.only <|
        describe "Differ"
            [ test "subst" <|
                \_ -> Differ.diff a1 b1 |> Expect.equal diff1
            , test "differentialTransform" <|
                \_ -> Differ.differentialTransform double dR a1x |> Expect.equal [ 2, 20, 6 ]
            ]

module TokenTest exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Parser.Token as Token
import Test exposing (..)


idemTest input =
    test input <|
        \_ ->
            input
                |> Token.idem
                |> Expect.equal input


suite : Test
suite =
    describe "Parser.Token"
        [ idemTest "a b c [x y z]"
        , idemTest "a b c [x [y z]]"
        , idemTest "a [b c] [x [y z]]"
        , idemTest "a $b c$ [x [y z]]"
        , idemTest "a `b c`  [x [y z]]"
        ]

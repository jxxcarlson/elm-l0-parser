module LambdaTest exposing (..)

import Dict exposing (Dict)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Parser.Expr exposing (Expr(..))
import Parser.Expression as Expression
import Parser.Simple as Simple exposing (ExprS(..))
import Render.Lambda as Lambda exposing (Lambda)
import Render.Text as Text
import Test exposing (..)


lambdaExpr : Maybe Expr
lambdaExpr =
    Expression.parse_ "[lambda bi x [b [i x]]]" |> List.head


expr : Maybe Expr
expr =
    Expression.parse_ "[bi bird flower]" |> List.head


aExpr : Maybe Expr
aExpr =
    Expression.parse_ "a" |> List.head


fExpr : Maybe Expr
fExpr =
    Expression.parse_ "[f x]" |> List.head


lambda : Maybe Lambda
lambda =
    Maybe.andThen Lambda.extract lambdaExpr


lambdaDict : Dict String Lambda
lambdaDict =
    Lambda.insert lambda Dict.empty


expanded : Maybe Expr
expanded =
    Maybe.map (Lambda.expand lambdaDict) expr


suite : Test
suite =
    describe "Render.Lambda"
        [ test "subst" <|
            \_ -> Maybe.map3 Lambda.subst aExpr (Just "x") fExpr |> Maybe.map Simple.simplify |> Expect.equal (Just (ExprS "f" [ TextS "a" ]))
        , Test.only <|
            test "expand" <|
                \_ ->
                    expr
                        |> Maybe.map (Lambda.expand lambdaDict)
                        |> Maybe.map Simple.simplify
                        |> Expect.equal (Just (ExprS "group" [ ExprS "b" [ TextS " ", ExprS "i" [ TextS " bird" ] ], ExprS "b" [ TextS " ", ExprS "i" [ TextS " flower" ] ] ]))
        ]

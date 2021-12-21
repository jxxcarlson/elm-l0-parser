module Data.TestStuff exposing (..)

import Dict exposing (Dict)
import Parser.Expr exposing (Expr(..))
import Parser.Expression as Expression
import Parser.Simple as Simple exposing (ExprS(..), simplify)
import Render.Lambda as Lambda exposing (Lambda)


lambdaText =
    "[lambda bi x [b [i x]]]"


lambdaExpr : Maybe Expr
lambdaExpr =
    Expression.parse "[lambda bi x [b [i x]]]" |> List.head


expr : Maybe Expr
expr =
    Expression.parse "[bi [bird flower]]" |> List.head


lambda : Maybe Lambda
lambda =
    Maybe.andThen Lambda.extract lambdaExpr


lambdaDict : Dict String Lambda
lambdaDict =
    Lambda.insert lambda Dict.empty


expanded : Maybe Expr
expanded =
    Maybe.map (Lambda.expand lambdaDict) expr

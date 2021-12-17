module Render.Lambda exposing (apply, expand, extract, insert)

import Dict exposing (Dict)
import Parser.Expr exposing (Expr(..))


type alias Lambda =
    { name : String, vars : List String, body : Expr }


extract : Expr -> Maybe Lambda
extract expr_ =
    case extractLambda1 expr_ of
        Just ( args, maybeExpr ) ->
            case maybeExpr of
                Just expr ->
                    case List.head args of
                        Nothing ->
                            Nothing

                        Just fname ->
                            Just { name = fname, vars = List.drop 1 args, body = expr }

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


{-| helper for extract
-}
extractLambda1 : Expr -> Maybe ( List String, Maybe Expr )
extractLambda1 expr_ =
    case expr_ of
        Expr name exprs meta ->
            if name == "lambda" then
                extractLambda2 (Just { input = exprs, args = [], expr = Nothing })
                    |> Maybe.map (\data -> ( data.args |> List.reverse, data.expr ))

            else
                Nothing

        _ ->
            Nothing


{-| helper for extractLambda1
-}
extractLambda2 : Maybe { input : List Expr, args : List String, expr : Maybe Expr } -> Maybe { input : List Expr, args : List String, expr : Maybe Expr }
extractLambda2 x =
    case x of
        Nothing ->
            Nothing

        Just ({ input, args, expr } as data) ->
            case input of
                (Text str _) :: rest ->
                    if String.trim str == "" then
                        extractLambda2 (Just { data | input = rest })

                    else
                        extractLambda2 (Just { data | input = rest, args = str :: args })

                expr_ :: [] ->
                    Just { data | expr = Just expr_ }

                _ ->
                    Nothing


{-| Insert a lambda in the dictionary
-}
insert : Maybe Lambda -> Dict String Lambda -> Dict String Lambda
insert data dict =
    case data of
        Nothing ->
            dict

        Just lambda ->
            Dict.insert lambda.name lambda dict


{-| Expand the given expression using the given dictionary of lambdas.
-}
expand : Dict String Lambda -> Expr -> Expr
expand dict expr =
    case expr of
        Expr name _ _ ->
            case Dict.get name dict of
                Nothing ->
                    expr

                Just lambda ->
                    apply lambda expr

        _ ->
            expr


{-| Substitute a for all occurrences of (Text var ..) in e
-}
subst : Expr -> String -> Expr -> Expr
subst a var body =
    case body of
        Text v meta ->
            if v == var then
                a

            else
                body

        Expr name exprs meta ->
            Expr name (List.map (subst a var) exprs) meta

        _ ->
            body


{-| Assume that var x is bound in a. For each expression e in exprs,
compute subst a x e. Let exprs2 be the resulting list. Return
E "group" exprs2 ...
-}
substInList : Expr -> String -> List Expr -> Expr
substInList a var exprs =
    Expr "group" (List.map (\e -> subst e var a) exprs) { begin = 0, end = 0, index = 0 }


{-| Apply a lambda to an expression.
-}
apply : Lambda -> Expr -> Expr
apply lambda expr =
    case List.head lambda.vars of
        Nothing ->
            -- Only handle one var lambdas for now
            expr

        Just var ->
            case expr of
                Expr fname_ exprs _ ->
                    if lambda.name == fname_ then
                        substInList lambda.body var exprs

                    else
                        expr

                _ ->
                    expr

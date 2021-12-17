module Render.Lambda exposing (apply, extract, store)

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


extract_ : Expr -> Maybe ( List String, Expr )
extract_ expr_ =
    case extractLambda1 expr_ of
        Just ( args, maybeExpr ) ->
            case maybeExpr of
                Just expr ->
                    Just ( args, expr )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


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



-- DIV


store : Maybe ( List String, Expr ) -> Dict String ( List String, Expr ) -> Dict String ( List String, Expr )
store data dict =
    case data of
        Nothing ->
            dict

        Just ( args_, expr ) ->
            case args_ of
                name :: args ->
                    Dict.insert name ( args, expr ) dict

                _ ->
                    dict



--expand : Dict String ( List String, Expr ) -> Expr -> Expr
--expand dict expr =
--    case expr of
--        Expr name exprs meta ->
--            case Dict.get name dict of
--                Nothing ->
--                    Expr name (List.map (expand dict) exprs) meta
--
--                --Just ( args, body ) ->
--                --    applyLambda name ( args, body ) expr
--                _ ->
--                    expr
--
--        _ ->
--            expr
--


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


substInList : Expr -> String -> List Expr -> Expr
substInList a var exprs =
    Expr "group" (List.map (\e -> subst e var a) exprs) { begin = 0, end = 0, index = 0 }


{-| if e is (Expr fname ...) then return subst var bdy e); otherwise return e
-}
apply : Lambda -> Expr -> Expr
apply lambda expr =
    case List.head lambda.vars of
        Nothing ->
            -- Only handle one var lambdas for now
            expr |> Debug.log "(1)"

        Just var ->
            case expr of
                Expr fname_ exprs _ ->
                    if lambda.name == fname_ then
                        --subst expr var lambda.body |> Debug.log "(2)"
                        substInList lambda.body var exprs |> Debug.log "(2)"

                    else
                        expr |> Debug.log "(3)"

                _ ->
                    expr |> Debug.log "(4)"

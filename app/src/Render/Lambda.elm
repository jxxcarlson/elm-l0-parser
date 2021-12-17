module Render.Lambda exposing (extract, store)

import Dict exposing (Dict)
import Parser.Expr exposing (Expr(..))


type alias Lambda =
    { name : String, args : List String, body : Expr }


extract : Expr -> Maybe ( List String, Expr )
extract expr_ =
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


{-| if e is (Expr fname ...) then return subst var bdy e); otherwise return e
-}
apply : String -> String -> Expr -> Expr -> Expr
apply fname var body e =
    case e of
        (Expr fname_ exprs meta) as expr ->
            if fname == fname_ then
                subst var body e

            else
                e

        _ ->
            e


{-| Substitute a for all occurrences of (Text var ..) in e
-}
subst : String -> Expr -> Expr -> Expr
subst var a e =
    case e of
        Text v meta ->
            if v == var then
                a

            else
                e

        Expr name exprs meta ->
            Expr name (List.map (subst var a) exprs) meta

        _ ->
            e

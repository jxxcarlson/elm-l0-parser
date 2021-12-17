module Render.Accumulator exposing
    ( Accumulator
    , make
    , storeLambda
    , subst
    , transformAST
    )

import Dict exposing (Dict)
import Either exposing (Either(..))
import Parser.Block exposing (BlockType(..), L0BlockE(..))
import Parser.Expr exposing (Expr(..))
import Render.ASTTools as ASTTools
import Render.Vector as Vector exposing (Vector)
import Tree exposing (Tree)


type alias Accumulator =
    { headingIndex : Vector
    , numberedItemIndex : Int
    , environment : Dict String ( List String, Expr )
    }



-- getLambda : String -> Dict String ( List String, Expr ) -> Maybe Lambda
-- getLambda : comparable -> Dict String ( List String, Expr ) -> Maybe { name : String, args : List str, expr : Expr }
-- getLambda : comparable -> Dict comparable (a, b) -> Maybe { name : comparable, args : a, expr : b }


getLambda : comparable -> Dict String ( List String, Expr ) -> Maybe { name : String, args : List String, expr : Expr }
getLambda name environment =
    Dict.get name environment |> Maybe.map (\( args, expr ) -> { name = name, args = args, expr = expr })


type alias Lambda =
    { name : String, args : List String, body : Expr }


transformAST : List (Tree L0BlockE) -> List (Tree L0BlockE)
transformAST ast =
    ast |> make |> Tuple.second


make : List (Tree L0BlockE) -> ( Accumulator, List (Tree L0BlockE) )
make ast =
    List.foldl (\tree ( acc_, ast_ ) -> transformAccumulateTree tree acc_ |> mapper ast_) ( init 4, [] ) ast
        |> (\( acc_, ast_ ) -> ( acc_, List.reverse ast_ ))


init : Int -> Accumulator
init k =
    { headingIndex = Vector.init k
    , numberedItemIndex = 0
    , environment = Dict.empty
    }


mapper ast_ ( acc_, tree_ ) =
    ( acc_, tree_ :: ast_ )


transformAccumulateTree : Tree L0BlockE -> Accumulator -> ( Accumulator, Tree L0BlockE )
transformAccumulateTree tree acc =
    let
        transformer : Accumulator -> L0BlockE -> ( Accumulator, L0BlockE )
        transformer =
            -- \acc_ block_ -> ( updateAccumulator block_ acc_, transformBlock acc_ block_ )
            \acc_ block_ ->
                let
                    newAcc =
                        updateAccumulator block_ acc_
                in
                ( newAcc, transformBlock newAcc block_ )
    in
    Tree.mapAccumulate transformer acc tree


transformBlock : Accumulator -> L0BlockE -> L0BlockE
transformBlock acc ((L0BlockE { args, blockType, children, content, indent, lineNumber, numberOfLines, name, id, sourceText }) as block) =
    case blockType of
        OrdinaryBlock [ "heading", level ] ->
            L0BlockE { args = args ++ [ Vector.toString acc.headingIndex ], blockType = blockType, children = children, content = content, indent = indent, lineNumber = lineNumber, numberOfLines = numberOfLines, name = name, id = id, sourceText = sourceText }

        OrdinaryBlock [ "numbered" ] ->
            L0BlockE { args = args ++ [ String.fromInt acc.numberedItemIndex ], blockType = blockType, children = children, content = content, indent = indent, lineNumber = lineNumber, numberOfLines = numberOfLines, name = name, id = id, sourceText = sourceText }

        _ ->
            block


updateAccumulator : L0BlockE -> Accumulator -> Accumulator
updateAccumulator ((L0BlockE { blockType, content }) as block) accumulator =
    case blockType of
        OrdinaryBlock [ "heading", level ] ->
            let
                headingIndex =
                    Vector.increment (String.toInt level |> Maybe.withDefault 0 |> (\x -> x - 1)) accumulator.headingIndex
            in
            { accumulator | headingIndex = headingIndex, numberedItemIndex = 0 }

        OrdinaryBlock [ "numbered" ] ->
            let
                numberedItemIndex =
                    accumulator.numberedItemIndex + 1
            in
            { accumulator | numberedItemIndex = numberedItemIndex }

        OrdinaryBlock [ "defs" ] ->
            case content of
                Left _ ->
                    accumulator

                Right exprs ->
                    { accumulator | environment = List.foldl (\lambda dict -> storeLambda (ASTTools.extractLambda lambda) dict) accumulator.environment exprs }

        _ ->
            { accumulator | numberedItemIndex = 0 }


storeLambda : Maybe ( List String, Expr ) -> Dict String ( List String, Expr ) -> Dict String ( List String, Expr )
storeLambda data dict =
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

module Render.TOC exposing (view)

import Either exposing (Either(..))
import Element exposing (Element)
import Element.Font as Font
import L0
import Parser.Block exposing (BlockType(..), L0BlockE(..))
import Parser.Expr exposing (Expr)
import Render.ASTTools
import Render.Elm
import Render.Msg exposing (MarkupMsg(..))
import Render.Settings
import Render.Utility


view : Int -> L0.AST -> Element Render.Msg.MarkupMsg
view counter ast =
    Element.column [ Element.spacing 8 ]
        (Element.el [ Font.bold, Font.size 18 ] (Element.text "Contents")
            :: List.map (viewTocItem counter Render.Settings.defaultSettings) (Render.ASTTools.tableOfContents ast)
        )


viewTocItem : Int -> Render.Settings.Settings -> L0BlockE -> Element Render.Msg.MarkupMsg
viewTocItem count settings (L0BlockE { args, content }) =
    case content of
        Left _ ->
            Element.none

        Right exprs ->
            let
                t =
                    Render.ASTTools.stringValueOfList exprs

                label : Element MarkupMsg
                label =
                    Element.paragraph [ tocIndent args ] (List.map (Render.Elm.render count settings) exprs)
            in
            -- Element.paragraph [ tocIndent args ] (List.map (Render.Elm.render count settings) exprs)
            Element.link [ Font.color (Element.rgb 0 0 0.8) ] { url = Render.Utility.internalLink t, label = label }


tocLink : String -> List Expr -> Element MarkupMsg
tocLink label exprList =
    let
        t =
            Render.ASTTools.stringValueOfList exprList
    in
    Element.link [] { url = Render.Utility.internalLink t, label = Element.text (label ++ " " ++ t) }


tocIndent args =
    Element.paddingEach { left = tocIndentAux args, right = 0, top = 0, bottom = 0 }


tocIndentAux args =
    case List.head args of
        Nothing ->
            0

        Just str ->
            String.toInt str |> Maybe.withDefault 0 |> (\x -> 12 * x)

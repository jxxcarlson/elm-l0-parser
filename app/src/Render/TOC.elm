module Render.TOC exposing (view)

import Either exposing (Either(..))
import Element exposing (Element)
import Element.Font as Font
import L0
import Parser.Block exposing (BlockType(..), L0BlockE(..))
import Render.ASTTools
import Render.Elm
import Render.Msg exposing (MarkupMsg(..))
import Render.Settings


view : Int -> L0.AST -> Element Render.Msg.MarkupMsg
view counter ast =
    Element.column [ Element.spacing 8 ]
        (List.map (viewTocItem counter Render.Settings.defaultSettings) (Render.ASTTools.tableOfContents ast))


viewTocItem : Int -> Render.Settings.Settings -> L0BlockE -> Element Render.Msg.MarkupMsg
viewTocItem count settings (L0BlockE { args, content }) =
    case content of
        Left _ ->
            Element.none

        Right exprs ->
            Element.paragraph [ tocIndent args ] (List.map (Render.Elm.render count settings) exprs)


tocIndent args =
    Element.paddingEach { left = tocIndentAux args, right = 0, top = 0, bottom = 0 }


tocIndentAux args =
    case List.head args of
        Nothing ->
            0

        Just str ->
            String.toInt str |> Maybe.withDefault 0 |> (\x -> 12 * x)



--
--renderTableOfContents : FrontendModel -> Element FrontendMsg
--renderTableOfContents model =
--    Element.column [ Element.spacing 8 ]
--        (List.map (viewTocItem model.counter Render.Settings.defaultSettings) model.tableOfContents)
--
--
--viewTitle : Int -> List L0BlockE -> Element FrontendMsg
--viewTitle count blocks =
--    case List.head blocks of
--        Nothing ->
--            Element.none
--
--        Just (L0BlockE { content }) ->
--            case content of
--                Left _ ->
--                    Element.none
--
--                Right realContent ->
--                    Element.paragraph [ Font.size (round Render.Settings.maxHeadingFontSize) ] (List.map (Render.Elm.render count Document.defaultSettings >> Element.map Render) realContent)

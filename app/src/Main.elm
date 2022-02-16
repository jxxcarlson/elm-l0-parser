module Main exposing (main)

import Browser
import Browser.Dom as Dom
import Compiler.ASTTools
import Compiler.Acc as RenderAccumulator
import Compiler.Differential
import Data.TestDoc
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import File.Download as Download
import Html exposing (Html)
import Html.Attributes as HtmlAttr exposing (attribute)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Json.Decode
import L0
import List.Extra
import Parser.Block exposing (ExpressionBlock, IntermediateBlock)
import Parser.BlockUtil
import Process
import Render.Block
import Render.L0
import Render.LaTeX as LaTeX
import Render.Msg exposing (L0Msg)
import Render.Settings as Settings exposing (Settings)
import Render.TOC
import Task exposing (Task)
import Tree


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { docLoaded : DocLoaded
    , initialText : String
    , sourceText : String
    , ast : L0.SyntaxTree
    , editRecord : Compiler.Differential.EditRecord (Tree.Tree IntermediateBlock) (Tree.Tree ExpressionBlock) (Tree.Tree (Element L0Msg))
    , count : Int
    , windowHeight : Int
    , windowWidth : Int
    , viewMode : ViewMode
    , message : String
    , linenumber : Int
    , searchSourceText : String

    -- SYNC
    , foundIds : List String
    , foundIdIndex : Int
    , syncRequestIndex : Int
    , searchCount : Int
    , selectedId : String
    , doSync : Bool
    }


type DocLoaded
    = NotLoaded
    | DocLoaded


type ViewMode
    = StandardView
    | LaTeXSource


viewModeToString : ViewMode -> String
viewModeToString mode =
    case mode of
        StandardView ->
            "Standard view"

        LaTeXSource ->
            "LaTeX"


type Msg
    = NoOp
    | InputText String
    | SelectedText String
    | InputSearch String
    | Search
    | ClearText
    | ExportLaTeX
    | LoadDocumentText String
    | IncrementCounter
    | SetViewMode ViewMode
    | Render Render.Msg.L0Msg
    | SetViewPortForElement (Result Dom.Error ( Dom.Element, Dom.Viewport ))
    | LoadInitialDocument
    | StartSync
    | NextSync


type alias Flags =
    { width : Int, height : Int }


chunker : String -> List (Tree.Tree IntermediateBlock)
chunker =
    L0.parseToIntermediateBlocks


parser : Tree.Tree IntermediateBlock -> Tree.Tree ExpressionBlock
parser =
    Tree.map Parser.BlockUtil.toExpressionBlockFromIntermediateBlock


renderer : Tree.Tree ExpressionBlock -> Tree.Tree (Element L0Msg)
renderer =
    Tree.map (Render.Block.render 0 Settings.defaultSettings)


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { docLoaded = NotLoaded
      , initialText = ""
      , sourceText = Data.TestDoc.text
      , ast = L0.parse Data.TestDoc.text |> RenderAccumulator.transformST
      , editRecord = Compiler.Differential.init chunker parser renderer Data.TestDoc.text
      , count = 0
      , windowHeight = flags.height
      , windowWidth = flags.width
      , viewMode = StandardView
      , message = "0"
      , linenumber = 0
      , searchSourceText = ""

      -- SYNC
      , foundIds = []
      , foundIdIndex = 0
      , syncRequestIndex = 0
      , searchCount = 0
      , selectedId = "(none)"
      , doSync = False
      }
    , Process.sleep 100 |> Task.perform (always LoadInitialDocument)
    )



-- Process.sleep 100 |> Task.perform (always (ChangeStyleSet "green"))


renderArgs =
    { width = 450
    , selectedId = "foobar"
    , generation = 0
    }


subscriptions model =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Search ->
            ( model, Cmd.none )

        SetViewMode viewMode ->
            ( { model | viewMode = viewMode }, Cmd.none )

        SelectedText str ->
            firstSyncLR model str

        SetViewPortForElement result ->
            case result of
                Ok ( element, viewport ) ->
                    ( { model | message = model.message ++ ", setting viewport" }, setViewPortForSelectedLine element viewport )

                Err _ ->
                    -- TODO: restore error message
                    -- ( { model | message = model.message ++ ", could not set viewport" }, Cmd.none )
                    ( model, Cmd.none )

        InputText str ->
            let
                editRecord =
                    Compiler.Differential.update chunker parser renderer model.editRecord str
            in
            ( { model
                | sourceText = str

                --, ast = L0.parse str |> RenderAccumulator.transformST
                , editRecord = editRecord
                , ast = editRecord.parsed |> RenderAccumulator.transformST
                , count = model.count + 1
              }
            , Cmd.none
            )

        InputSearch str ->
            ( { model | searchSourceText = str }, Cmd.none )

        ClearText ->
            ( { model
                | sourceText = ""
                , count = model.count + 1
              }
            , Cmd.none
            )

        LoadDocumentText text ->
            ( { model | sourceText = text, count = model.count + 1 }, Cmd.none )

        IncrementCounter ->
            ( model, Cmd.none )

        Render msg_ ->
            case msg_ of
                Render.Msg.SendMeta m ->
                    ( model, Cmd.none )

                Render.Msg.SendId line ->
                    ( { model | message = "Line " ++ line, linenumber = String.toInt line |> Maybe.withDefault 0 }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ExportLaTeX ->
            let
                textToExport =
                    LaTeX.export Settings.defaultSettings model.ast

                fileName =
                    "doc.tex"
            in
            ( model, Download.string fileName "application/x-latex" textToExport )

        LoadInitialDocument ->
            ( { model | docLoaded = DocLoaded, initialText = model.sourceText, message = "Doc loaded" }, Cmd.none )

        StartSync ->
            ( { model | doSync = not model.doSync }, Cmd.none )

        NextSync ->
            nextSyncLR model


firstSyncLR model searchSourceText =
    let
        data =
            let
                foundIds_ =
                    Compiler.ASTTools.matchingIdsInAST searchSourceText model.ast

                id_ =
                    List.head foundIds_ |> Maybe.withDefault "(nothing)"
            in
            { foundIds = foundIds_
            , foundIdIndex = 1
            , cmd = setViewportForElement id_
            , selectedId = id_
            , searchCount = 0
            }
    in
    ( { model
        | selectedId = data.selectedId
        , foundIds = data.foundIds
        , foundIdIndex = data.foundIdIndex
        , searchCount = data.searchCount
        , message = ("[" ++ data.selectedId ++ "]") :: data.foundIds |> String.join ", "
      }
    , data.cmd
    )


nextSyncLR model =
    let
        id_ =
            List.Extra.getAt model.foundIdIndex model.foundIds |> Maybe.withDefault "(nothing)"
    in
    ( { model
        | selectedId = id_
        , foundIdIndex = modBy (List.length model.foundIds) (model.foundIdIndex + 1)
        , searchCount = model.searchCount + 1
        , message = ("[" ++ id_ ++ "]") :: model.foundIds |> String.join ", "
      }
    , setViewportForElement id_
    )


download : String -> String -> String -> Cmd msg
download filename mimetype content =
    Download.string filename mimetype content



--
-- VIEW
--


setViewportForElement : String -> Cmd Msg
setViewportForElement id =
    Dom.getViewportOf "__RENDERED_TEXT__"
        |> Task.andThen (\vp -> getElementWithViewPort vp id)
        |> Task.attempt SetViewPortForElement


setViewPortForSelectedLine : Dom.Element -> Dom.Viewport -> Cmd Msg
setViewPortForSelectedLine element viewport =
    let
        y =
            viewport.viewport.y + element.element.y - element.element.height - 100
    in
    Task.attempt (\_ -> NoOp) (Dom.setViewportOf "__RENDERED_TEXT__" 0 y)


getElementWithViewPort : Dom.Viewport -> String -> Task Dom.Error ( Dom.Element, Dom.Viewport )
getElementWithViewPort vp id =
    Dom.getElement id
        |> Task.map (\el -> ( el, vp ))


view : Model -> Html Msg
view model =
    Element.layoutWith { options = [ focusStyle noFocus ] } [ bgGray 0.2, clipX, clipY ] (mainColumn model)


noFocus : Element.FocusStyle
noFocus =
    { borderColor = Nothing
    , backgroundColor = Nothing
    , shadow = Nothing
    }


mainColumn : Model -> Element Msg
mainColumn model =
    column (mainColumnStyle model)
        [ column [ centerY, paddingEach { top = 46, bottom = 0, left = 0, right = 0 }, spacing 8, width (px appWidth_), height (px (appHeight_ model)) ]
            [ -- title "L3 Demo App"
              column [ height (panelHeight model), spacing 12 ]
                [ row [ spacing 12 ] [ editor model, rhs model ]
                ]
            , row [ Element.spacing 24, Element.paddingXY 8 0, Element.height (px 30), Element.width fill, Font.size 14, Background.color (Element.rgb 0.3 0.3 0.3), Font.color (Element.rgb 1 1 1) ]
                [ exportLaTeXButton, syncButton, nextSyncButton model.foundIds, Element.text <| "Messages: " ++ model.message ]
            ]
        ]



-- PARAMETERS


widePanelWidth_ =
    2 * panelWidth_


panelWidth_ =
    560


appHeight_ model =
    model.windowHeight - 140


panelHeight model =
    px (appHeight_ model - 160)


innerPanelHeight model =
    appHeight_ model - 180


appWidth_ =
    2 * panelWidth_ + 15



-- BEGIN CODE MIRROR EDITOR


editor model =
    column [ height (px (innerPanelHeight model)), moveUp 4 ]
        [ editor_ model
        ]


makeAttribute : String -> String -> Attribute msg
makeAttribute name value =
    HtmlAttr.attribute name value |> Element.htmlAttribute


editor_ : Model -> Element Msg
editor_ model =
    Element.el
        [ Element.htmlAttribute onSelectionChange
        , Element.htmlAttribute onTextChange
        , htmlId "editor-here"
        , width (px 550)
        , Background.color (Element.rgb255 0 68 85)
        , Font.color (Element.rgb 0.85 0.85 0.85)
        , Font.size 12
        ]
        (Element.html
            (Html.node "codemirror-editor"
                [ HtmlAttr.attribute "text" (loadedDocument model)
                , HtmlAttr.attribute "linenumber" (String.fromInt model.linenumber)
                , HtmlAttr.attribute "selection" (stringOfBool model.doSync)
                ]
                []
            )
        )


stringOfBool bool =
    case bool of
        False ->
            "false"

        True ->
            "true"


loadedDocument model =
    case model.docLoaded of
        NotLoaded ->
            "(((empty)))"

        DocLoaded ->
            model.initialText


onTextChange : Html.Attribute Msg
onTextChange =
    textDecoder
        |> Json.Decode.map InputText
        |> Html.Events.on "text-change"


onSelectionChange : Html.Attribute Msg
onSelectionChange =
    textDecoder
        |> Json.Decode.map SelectedText
        |> Html.Events.on "selected-text"


textDecoder : Json.Decode.Decoder String
textDecoder =
    Json.Decode.string
        |> Json.Decode.at [ "detail" ]



-- END CODE MIRROR EDITOR


searchField : Model -> Element Msg
searchField model =
    inputFieldTemplate [ onEnter Search |> Element.htmlAttribute ] Element.fill "Search ..." InputSearch model.searchSourceText


onEnter : Msg -> Html.Attribute Msg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                Json.Decode.succeed msg

            else
                Json.Decode.fail "not ENTER"
    in
    on "keydown" (keyCode |> Json.Decode.andThen isEnter)


inputFieldTemplate attr width_ default msg text =
    Input.text ([ Element.moveUp 5, Font.size 16, Element.height (px 33), Element.width width_ ] ++ attr)
        { onChange = msg
        , text = text
        , label = Input.labelHidden default
        , placeholder = Just <| Input.placeholder [ Element.moveUp 5 ] (Element.text default)
        }


green =
    Element.rgb 0 1 1


darkGreen =
    Element.rgb 0 0.4 0.4


white =
    Element.rgb 1 1 1


keyIt : Int -> List b -> List ( String, b )
keyIt k list =
    List.indexedMap (\i e -> ( String.fromInt (i + k), e )) list


title : String -> Element msg
title str =
    row [ centerX, fontGray 0.9 ] [ text str ]


rhs : Model -> Element Msg
rhs model =
    column [ spacing 8 ]
        [ row
            [ fontGray 0.9
            , spacing 12
            , moveUp 9
            , Font.size 14
            ]
            [ text ("generation: " ++ String.fromInt model.count)
            , wordCountElement model.sourceText
            ]
        , renderedText model
        ]


wordCount : String -> Int
wordCount str =
    str |> String.words |> List.length


wordCountElement : String -> Element Msg
wordCountElement str =
    row [ spacing 8 ] [ el [] (text <| "words:"), el [] (text <| String.fromInt <| wordCount <| str) ]



-- manualCss : String -> Html msg


manualCss : String -> Element msg
manualCss id =
    Html.node "style"
        []
        [ """
            #{id} { background-color: yellow;}
          """
            |> String.replace "{id}" id
            |> Html.text
        ]
        |> Element.html


{-| Need to highlight the element with id model.selectedId
-}
renderedText : Model -> Element Msg
renderedText model =
    column
        [ spacing 24
        , paddingXY 24 36
        , width (px panelWidth_)
        , height (px (innerPanelHeight model))
        , scrollbarY
        , moveUp 9
        , Font.size 14
        , alignTop
        , htmlId "__RENDERED_TEXT__"
        , Background.color (Element.rgb255 255 255 255)
        ]
        ((Render.TOC.view model.count Settings.defaultSettings model.ast |> Element.map Render)
            :: render model.selectedId model.ast model.count
        )


render1 : String -> Int -> List (Element Msg)
render1 sourceText count =
    sourceText
        |> Render.L0.renderFromString count defaultSettings
        |> List.map (Element.map Render)


render : String -> L0.SyntaxTree -> Int -> List (Element Msg)
render selectedId ast count =
    Render.L0.renderFromAST count (settings selectedId) ast
        |> List.map (Element.map Render)


htmlId str =
    Element.htmlAttribute (HtmlAttr.id str)


defaultSettings : Settings
defaultSettings =
    { width = 500
    , titleSize = 30
    , paragraphSpacing = 28
    , showTOC = True
    , showErrorMessages = False
    , selectedId = ""
    }


settings selectedId =
    { defaultSettings | width = 500, paragraphSpacing = 42, showErrorMessages = True, selectedId = selectedId }



-- BUTTONS


defaultButtonColor =
    Element.rgb255 60 60 60


buttonColor buttonMode currentMode =
    if buttonMode == currentMode then
        Element.rgb255 130 12 9

    else
        Element.rgb255 60 60 60


clearTextButton : Element Msg
clearTextButton =
    Input.button buttonStyle2
        { onPress = Just ClearText
        , label = el [ centerX, centerY, Font.size 14 ] (text "Clear")
        }


exportLaTeXButton : Element Msg
exportLaTeXButton =
    Input.button buttonStyle2
        { onPress = Just ExportLaTeX
        , label = el [ centerX, centerY, Font.size 14 ] (text "Export LaTeX")
        }


syncButton : Element Msg
syncButton =
    Input.button buttonStyle2
        { onPress = Just StartSync
        , label = el [ centerX, centerY, Font.size 14 ] (text "Sync")
        }


nextSyncButton : List String -> Element Msg
nextSyncButton foundIds =
    if List.length foundIds < 2 then
        Element.none

    else
        Input.button buttonStyle2
            { onPress = Just NextSync
            , label = el [ centerX, centerY, Font.size 14 ] (text "Next sync")
            }


setViewMode : Model -> ViewMode -> Element Msg
setViewMode model viewMode =
    Input.button (activeButtonStyle (viewMode == model.viewMode))
        { onPress = Just (SetViewMode viewMode)
        , label = el [ centerX, centerY, Font.size 14 ] (text (viewModeToString viewMode))
        }


dummyButton : Element Msg
dummyButton =
    row [ Background.color defaultButtonColor ]
        [ Input.button buttonStyle
            { onPress = Nothing
            , label = el [ centerX, centerY, Font.size 14 ] (text "Rendered text")
            }
        ]



--
-- STYLE
--


mainColumnStyle model =
    [ centerX
    , centerY
    , bgGray 0.5
    , paddingXY 20 20
    , width (px (appWidth_ + 40))
    , height (px (appHeight_ model + 40))
    ]


buttonStyle =
    [ Font.color (rgb255 255 255 255)
    , paddingXY 15 8
    ]


buttonStyle2 =
    [ Font.color (rgb255 255 255 255)
    , Background.color (rgb255 0 0 160)
    , paddingXY 15 8
    , mouseDown [ Background.color (rgb255 180 180 255) ]
    ]


activeButtonStyle isSelected =
    if isSelected then
        [ Font.color (rgb255 255 255 255)
        , Background.color (rgb255 140 0 0)
        , paddingXY 15 8
        , mouseDown [ Background.color (rgb255 255 180 180) ]
        ]

    else
        [ Font.color (rgb255 255 255 255)
        , Background.color (rgb255 0 0 160)
        , paddingXY 15 8
        , mouseDown [ Background.color (rgb255 180 180 255) ]
        ]


grayColor g =
    Element.rgb g g g


whiteColor =
    grayColor 1


fontGray g =
    Font.color (Element.rgb g g g)


bgGray g =
    Background.color (Element.rgb g g g)

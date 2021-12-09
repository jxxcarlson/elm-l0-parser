module Block.Block exposing (..)

import Block.Line as Line exposing (LineType(..))


type Block
    = Block
        { name : Maybe String
        , content : String
        , children : List Block
        }


type alias State =
    { blocks : List Block
    , workingBlock : Maybe Block
    , currentBlock : Maybe Block
    , lines : List String
    , indent : Int
    , previousLineType : LineType
    }


init lines =
    { blocks = []
    , workingBlock = Nothing
    , currentBlock = Nothing
    , lines = lines
    , indent = 0
    , previousLineType = Blank
    }


nextStep : State -> Step State State
nextStep state =
    case List.head state.lines of
        Nothing ->
            Done state

        Just line ->
            let
                lineType =
                    Line.classifyLine line
            in
            case compare (Line.indentOf lineType) (Line.indentOf state.previousLineType) of
                GT ->
                    Loop state

                EQ ->
                    Loop state

                LT ->
                    Loop state



--if Line.isBlank state.previousLineType && Line.isBlank lineType then
--    if Line.indentOf lineType == 0 then
--        Loop <| commitBlock state
--
--    else
--        Loop <| terminateBlock "" state
--
--else if Line.indentOf lineType < state.indent then
--    Loop <| beginBlock lineType line state
--
--else if Line.indentOf lineType > state.indent then
--    Loop <| beginBlock lineType line state
--
--else
--    -- addToBlock line state
--    Done state


commitBlock : State -> State
commitBlock state =
    case state.workingBlock of
        Nothing ->
            state

        Just block ->
            { state | blocks = block :: state.blocks, currentBlock = Nothing, workingBlock = Nothing }


terminateBlock : String -> State -> State
terminateBlock line state =
    case ( state.workingBlock, state.currentBlock ) of
        ( Just (Block workingData), Just (Block currentData) ) ->
            state

        --let
        --    newBlock =
        --       Block { data | content = data.content ++ "\n" ++ line }
        --in
        --{ state | blocks = newBlock :: state.blocks }
        _ ->
            state


beginBlock : LineType -> String -> State -> State
beginBlock type_ line state =
    state



-- LOOP


type Step state a
    = Loop state
    | Done a


loop : state -> (state -> Step state a) -> a
loop s f =
    case f s of
        Loop s_ ->
            loop s_ f

        Done b ->
            b

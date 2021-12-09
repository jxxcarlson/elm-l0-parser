module Block.Line exposing (LineType(..), classifyLine, indentOf, isBlank)

import Parser exposing ((|.), (|=), Parser)


type LineType
    = Blank Int
    | BeginBlock Int
    | BeginVerbatimBlock Int
    | OrdinaryLine Int
    | Unclassified


isBlank : LineType -> Bool
isBlank lt =
    case lt of
        Blank _ ->
            True

        _ ->
            False


indentOf : LineType -> Int
indentOf lineType =
    case lineType of
        Blank k ->
            k

        BeginBlock k ->
            k

        BeginVerbatimBlock k ->
            k

        OrdinaryLine k ->
            k

        Unclassified ->
            0


classifyLine : String -> LineType
classifyLine str =
    case Parser.run prefix str of
        Err _ ->
            Unclassified 0

        Ok result ->
            case result.content of
                "" ->
                    Blank result.prefixLength

                "|" ->
                    BeginBlock result.prefixLength

                "||" ->
                    BeginVerbatimBlock result.prefixLength

                _ ->
                    OrdinaryLine result.prefixLength


prefix : Parser { content : String, prefixLength : Int }
prefix =
    Parser.succeed (\prefixStart prefixEnd end content -> { prefixLength = prefixEnd - prefixStart, content = String.slice prefixEnd end content })
        |= Parser.getOffset
        |. Parser.chompWhile (\c -> c == ' ')
        |= Parser.getOffset
        |. Parser.chompWhile (\c -> c /= ' ')
        |= Parser.getOffset
        |= Parser.getSource

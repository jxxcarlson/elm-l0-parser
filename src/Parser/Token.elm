module Parser.Token exposing
    ( Meta
    , Token(..)
    , TokenType(..)
    , idem
    , idemTest
    , init
    , run
    , toString
    , type_
    )

import Parser.Advanced as Parser exposing (DeadEnd, Parser)
import Parser.Helpers exposing (Step(..), loop)
import Parser.Tools as PT exposing (Context, Problem)


idem : String -> String
idem str =
    str |> run |> List.reverse |> toString


idemTest : String -> Bool
idemTest str =
    str == idem str



-- TYPES


type Token
    = LB Meta
    | RB Meta
    | S String Meta
    | W String Meta
    | MathToken Meta
    | CodeToken Meta
    | TokenError (List (DeadEnd Context Problem)) Meta


type alias Meta =
    { begin : Int, end : Int, index : Int }


type alias State a =
    { source : String
    , scanpointer : Int
    , tokenIndex : Int
    , sourceLength : Int
    , tokens : List a
    , lastToken : Maybe Token
    , lastTokenType : Maybe TokenType
    , mode : Mode
    }


type Mode
    = Normal
    | InMath
    | InCode


type TokenType
    = TLB
    | TRB
    | TS
    | TW
    | TMath
    | TCode
    | TTokenError


type_ : Token -> TokenType
type_ token =
    case token of
        LB _ ->
            TLB

        RB _ ->
            TRB

        S _ _ ->
            TS

        W _ _ ->
            TW

        MathToken _ ->
            TMath

        CodeToken _ ->
            TCode

        TokenError _ _ ->
            TTokenError


getMeta : Token -> Meta
getMeta token =
    case token of
        LB m ->
            m

        RB m ->
            m

        S _ m ->
            m

        W _ m ->
            m

        MathToken m ->
            m

        CodeToken m ->
            m

        TokenError _ m ->
            m


stringValue : Token -> String
stringValue token =
    case token of
        LB _ ->
            "["

        RB _ ->
            "]"

        S str _ ->
            str

        W str _ ->
            str

        MathToken _ ->
            "$"

        CodeToken _ ->
            "`"

        TokenError _ _ ->
            "tokenError"


toString : List Token -> String
toString tokens =
    List.map stringValue tokens |> String.join ""


length : Token -> Int
length token =
    case token of
        LB meta ->
            meta.end - meta.begin

        RB meta ->
            meta.end - meta.begin

        S _ meta ->
            meta.end - meta.begin

        MathToken meta ->
            meta.end - meta.begin

        CodeToken meta ->
            meta.end - meta.begin

        W _ meta ->
            meta.end - meta.begin

        TokenError _ meta ->
            meta.end - meta.begin


init : String -> State a
init str =
    { source = str, scanpointer = 0, sourceLength = String.length str, tokens = [], lastToken = Just (S "" { begin = 0, end = 0, index = 0 }), lastTokenType = Just TS, tokenIndex = 0, mode = Normal }


type alias TokenParser =
    Parser Context Problem Token


run : String -> List Token
run source =
    loop (init source) nextStep


{-|

    NOTES. In the computation of the end field of the Meta component of a Token,
    one must use the code `end = start + data.end - data.begin  - 1`.  The
    `-1` is because the data.end comes from the position of the scanPointer,
    which is at this juncture pointing one character beyond the string chomped.

-}
get : State Token -> Int -> String -> Token
get state start input =
    case Parser.run (tokenParser state.mode start state.tokenIndex) input of
        Ok token ->
            token

        Err errorList ->
            TokenError errorList { begin = start, end = start + 1, index = state.tokenIndex }


nextStep : State Token -> Step (State Token) (List Token)
nextStep state =
    if state.scanpointer >= state.sourceLength then
        Done state.tokens

    else
        let
            token =
                get state state.scanpointer (String.dropLeft state.scanpointer state.source)

            newScanPointer =
                state.scanpointer + length token + 1

            ( newToken, mergeStatus ) =
                mergeTokens state.lastToken token

            tokens =
                case mergeStatus of
                    TokensUnchanged ->
                        token :: state.tokens

                    TokensMerged ->
                        newToken :: List.drop 1 state.tokens

            lastToken =
                if List.member state.lastTokenType [ Nothing, Just TLB, Just TRB ] then
                    Nothing

                else
                    Just newToken
        in
        Loop
            { state
                | tokens = tokens
                , lastToken = lastToken
                , lastTokenType = Just (type_ token)
                , scanpointer = newScanPointer
                , tokenIndex = state.tokenIndex + 1
                , mode = newMode token state.mode
            }


isTextToken : Token -> Bool
isTextToken token =
    List.member (type_ token) [ TW, TS ]


type MergeStatus
    = TokensUnchanged
    | TokensMerged


mergeTokens : Maybe Token -> Token -> ( Token, MergeStatus )
mergeTokens lastToken_ token =
    case lastToken_ of
        Nothing ->
            ( token, TokensUnchanged )

        Just lastToken ->
            if isTextToken lastToken && isTextToken token then
                ( mergeTokensAux lastToken token, TokensMerged )

            else
                ( token, TokensUnchanged )


mergeTokensAux : Token -> Token -> Token
mergeTokensAux lastToken currentToken =
    let
        lastTokenMeta =
            getMeta lastToken

        currentTokenMeta =
            getMeta currentToken

        meta =
            { begin = lastTokenMeta.begin, end = currentTokenMeta.end, index = currentTokenMeta.index }
    in
    S (stringValue lastToken ++ stringValue currentToken) meta


newMode : Token -> Mode -> Mode
newMode token currentMode =
    case currentMode of
        Normal ->
            case token of
                MathToken _ ->
                    InMath

                CodeToken _ ->
                    InCode

                _ ->
                    Normal

        InMath ->
            case token of
                MathToken _ ->
                    Normal

                _ ->
                    InMath

        InCode ->
            case token of
                CodeToken _ ->
                    Normal

                _ ->
                    InCode


{-| Expression.Tokenizer.tokenParser calls L1.tokenParser
with arguments tokenStack and start. The first argument
is not used (although it is for the Markdown parser)
-}
tokenParser : Mode -> Int -> Int -> TokenParser
tokenParser mode start index =
    case mode of
        Normal ->
            tokenParser_ start index

        InMath ->
            mathParser_ start index

        InCode ->
            codeParser_ start index


languageChars =
    [ '[', ']', '`', '$' ]


mathChars =
    [ '$' ]


codeChars =
    [ '`' ]


tokenParser_ : Int -> Int -> TokenParser
tokenParser_ start index =
    Parser.oneOf
        [ textParser start index
        , leftBracketParser start index
        , rightBracketParser start index
        , mathParser start index
        , codeParser start index
        , whiteSpaceParser start index
        ]


mathParser_ : Int -> Int -> TokenParser
mathParser_ start index =
    Parser.oneOf
        [ mathTextParser start index
        , mathParser start index
        , whiteSpaceParser start index
        ]


codeParser_ : Int -> Int -> TokenParser
codeParser_ start index =
    Parser.oneOf
        [ codeTextParser start index
        , codeParser start index
        , whiteSpaceParser start index
        ]


whiteSpaceParser : Int -> Int -> TokenParser
whiteSpaceParser start index =
    PT.text (\c -> c == ' ') (\c -> c == ' ')
        |> Parser.map (\data -> W data.content { begin = start, end = start, index = index })


leftBracketParser : Int -> Int -> TokenParser
leftBracketParser start index =
    PT.text (\c -> c == '[') (\_ -> False)
        |> Parser.map (\_ -> LB { begin = start, end = start, index = index })


rightBracketParser : Int -> Int -> TokenParser
rightBracketParser start index =
    PT.text (\c -> c == ']') (\_ -> False)
        |> Parser.map (\_ -> RB { begin = start, end = start, index = index })


textParser start index =
    PT.text (\c -> not <| List.member c (' ' :: languageChars)) (\c -> not <| List.member c (' ' :: languageChars))
        |> Parser.map (\data -> S data.content { begin = start, end = start + data.end - data.begin - 1, index = index })


mathTextParser start index =
    PT.text (\c -> not <| List.member c (' ' :: mathChars)) (\c -> not <| List.member c (' ' :: languageChars))
        |> Parser.map (\data -> S data.content { begin = start, end = start + data.end - data.begin - 1, index = index })


codeTextParser start index =
    PT.text (\c -> not <| List.member c (' ' :: codeChars)) (\c -> not <| List.member c (' ' :: languageChars))
        |> Parser.map (\data -> S data.content { begin = start, end = start + data.end - data.begin - 1, index = index })


mathParser : Int -> Int -> TokenParser
mathParser start index =
    PT.text (\c -> c == '$') (\_ -> False)
        |> Parser.map (\_ -> MathToken { begin = start, end = start, index = index })


codeParser : Int -> Int -> TokenParser
codeParser start index =
    PT.text (\c -> c == '`') (\_ -> False)
        |> Parser.map (\_ -> CodeToken { begin = start, end = start, index = index })

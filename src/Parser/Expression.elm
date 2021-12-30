module Parser.Expression exposing
    ( State
    , parse
    , parseToState
    )

import Either exposing (Either(..))
import List.Extra
import Parser.Expr exposing (Expr(..))
import Parser.Helpers as Helpers
import Parser.Match as M
import Parser.Symbol as Symbol exposing (Symbol(..))
import Parser.Token as Token exposing (Meta, Token(..), TokenType(..))



-- TYPES


type alias State =
    { step : Int
    , tokens : List Token
    , numberOfTokens : Int
    , tokenIndex : Int
    , committed : List Expr
    , stack : List Token
    , messages : List String
    }



-- STATE FOR THE PARSER


initWithTokens : List Token -> State
initWithTokens tokens =
    { step = 0
    , tokens = List.reverse tokens
    , numberOfTokens = List.length tokens
    , tokenIndex = 0
    , committed = []
    , stack = []
    , messages = []
    }


init : String -> State
init str =
    let
        tokens =
            Token.run str |> List.reverse
    in
    { step = 0
    , tokens = tokens
    , numberOfTokens = List.length tokens
    , tokenIndex = 0
    , committed = []
    , stack = []
    , messages = []
    }



-- Exposed functions


parse : String -> List Expr
parse str =
    str
        |> Token.run
        |> parseTokenList


parseToState : String -> State
parseToState str =
    str
        |> Token.run
        |> parseTokenListToState



-- PARSER


parseTokenListToState : List Token -> State
parseTokenListToState tokens =
    tokens |> initWithTokens |> run


parseTokenList : List Token -> List Expr
parseTokenList tokens =
    parseTokenListToState tokens |> .committed


run : State -> State
run state =
    loop state nextStep
        |> (\state_ -> { state_ | committed = List.reverse state_.committed })


nextStep : State -> Step State State
nextStep state =
    case List.Extra.getAt state.tokenIndex state.tokens of
        Nothing ->
            if List.isEmpty state.stack then
                Done state

            else
                -- the stack is not empty, so we need to handle the parse error
                recoverFromError state

        Just token ->
            pushToken token { state | tokenIndex = state.tokenIndex + 1 }
                |> reduceState
                |> (\st -> { st | step = st.step + 1 })
                |> Loop



-- PUSH


pushToken : Token -> State -> State
pushToken token state =
    case token of
        S _ _ ->
            pushOrCommit token state

        W _ _ ->
            pushOrCommit token state

        MathToken _ ->
            pushOnStack token state

        CodeToken _ ->
            pushOnStack token state

        LB _ ->
            pushOnStack token state

        RB _ ->
            pushOnStack token state

        TokenError _ _ ->
            pushOnStack token state


pushOnStack : Token -> State -> State
pushOnStack token state =
    { state | stack = token :: state.stack }


pushOrCommit : Token -> State -> State
pushOrCommit token state =
    if List.isEmpty state.stack then
        commit token state

    else
        push token state


commit : Token -> State -> State
commit token state =
    case exprOfToken token of
        Nothing ->
            state

        Just expr ->
            { state | committed = expr :: state.committed }


exprOfToken : Token -> Maybe Expr
exprOfToken token =
    case token of
        S str loc ->
            Just (Text str loc)

        W str loc ->
            Just (Text str loc)

        _ ->
            Nothing


push : Token -> State -> State
push token state =
    { state | stack = token :: state.stack }



-- REDUCE


reduceState : State -> State
reduceState state =
    let
        symbols =
            state.stack |> Symbol.convertTokens |> List.reverse
    in
    if M.reducible symbols then
        case List.head symbols of
            Just L ->
                case eval (state.stack |> List.reverse) of
                    (Expr "invisible" [ Text message _ ] _) :: rest ->
                        { state | stack = [], committed = rest ++ state.committed, messages = Helpers.prependMessage message state.messages }

                    whatever ->
                        { state | stack = [], committed = whatever ++ state.committed }

            -- { state | stack = [], committed = eval (state.stack |> List.reverse) ++ state.committed }
            Just M ->
                { state | stack = [], committed = Verbatim "math" (Token.toString <| unbracket <| List.reverse state.stack) { begin = 0, end = 0, index = 0 } :: state.committed }

            Just C ->
                { state | stack = [], committed = Verbatim "code" (Token.toString <| unbracket <| List.reverse state.stack) { begin = 0, end = 0, index = 0 } :: state.committed }

            _ ->
                state

    else
        state


{-| remove first and last token
-}
unbracket : List a -> List a
unbracket list =
    List.drop 1 (List.take (List.length list - 1) list)


{-| areBracketed tokns == True iff tokens are derived from "[ ... ]"
-}
areBracketed : List Token -> Bool
areBracketed tokens =
    List.map Token.type_ (List.take 1 tokens)
        == [ TLB ]
        && List.map Token.type_ (List.take 1 (List.reverse tokens))
        == [ TRB ]


eval : List Token -> List Expr
eval tokens =
    if areBracketed tokens then
        let
            args =
                unbracket tokens
        in
        case List.head args of
            -- The reversed token list is of the form [LB name EXPRS RB], so return [Expr name (evalList EXPRS)]
            Just (S name meta) ->
                [ Expr name (evalList (List.drop 1 args)) meta ]

            Nothing ->
                -- this happens with input of "[]"
                [ errorMessageInvisible "[ ] not legal - you need something between the brackets", errorMessage "[??]" ]

            _ ->
                [ errorMessageInvisible "[  or [   ] not legal, try [something ...]", errorMessage <| "[" ++ Token.toString args ++ "?? ]" ]

    else
        []


evalList : List Token -> List Expr
evalList tokens =
    case List.head tokens of
        Just token ->
            case Token.type_ token of
                TLB ->
                    case M.match (Symbol.convertTokens2 tokens) of
                        Nothing ->
                            [ errorMessageInvisible "Error on match", Text "error on match" dummyLoc ]

                        Just k ->
                            let
                                ( a, b ) =
                                    M.splitAt (k + 1) tokens
                            in
                            eval a ++ evalList b

                _ ->
                    case exprOfToken token of
                        Just expr ->
                            expr :: evalList (List.drop 1 tokens)

                        Nothing ->
                            [ errorMessageInvisible "Error converting token", Text "error converting Token" dummyLoc ]

        _ ->
            []


errorMessageInvisible : String -> Expr
errorMessageInvisible message =
    Expr "invisible" [ Text message dummyLoc ] dummyLoc


errorMessage : String -> Expr
errorMessage message =
    Expr "red" [ Text message dummyLoc ] dummyLoc


errorMessageBold : String -> Expr
errorMessageBold message =
    Expr "bold" [ Expr "red" [ Text message dummyLoc ] dummyLoc ] dummyLoc


errorMessage2 : String -> Expr
errorMessage2 message =
    Expr "blue" [ Text message dummyLoc ] dummyLoc


colorRed : Expr -> Expr
colorRed expr =
    Expr "red" [ expr ] dummyLoc


colorFirstElementRed : State -> State
colorFirstElementRed state =
    let
        ( a, b ) =
            M.splitAt 1 state.committed

        newCommitted =
            List.map colorRed a ++ b
    in
    { state | committed = newCommitted }


addErrorMessage : String -> State -> State
addErrorMessage message state =
    let
        committed =
            errorMessage message :: state.committed
    in
    { state | committed = committed }


isReducible : List Token -> Bool
isReducible tokens =
    tokens |> List.reverse |> Symbol.convertTokens |> M.reducible


recoverFromError : State -> Step State State
recoverFromError state =
    case List.reverse state.stack of
        -- brackets with no intervening text
        (LB _) :: (RB meta) :: rest ->
            Loop
                { state
                    | committed = errorMessage "[?]" :: state.committed
                    , stack = []
                    , tokenIndex = meta.index + 1
                    , messages = Helpers.prependMessage "Brackets need to enclose something" state.messages
                }

        -- consecutive left brackets
        (LB _) :: (LB meta) :: rest ->
            Loop
                { state
                    | committed = errorMessage "[" :: state.committed
                    , stack = []
                    , tokenIndex = meta.index
                    , messages = Helpers.prependMessage "You have consecutive left brackets" state.messages
                }

        -- missing right bracket // OK
        (LB _) :: (S fName meta) :: rest ->
            Loop
                { state
                    | committed = errorMessage (errorSuffix rest) :: errorMessage2 ("[" ++ fName) :: state.committed
                    , stack = []
                    , tokenIndex = meta.index + 1
                    , messages = Helpers.prependMessage "Missing right bracket" state.messages
                }

        -- space after left bracket // OK
        (LB _) :: (W " " meta) :: rest ->
            Loop
                { state
                    | committed = errorMessage "[ - can't have space after the bracket " :: state.committed
                    , stack = []
                    , tokenIndex = meta.index + 1
                    , messages = Helpers.prependMessage "Can't have space after left bracket - try [something ..." state.messages
                }

        -- left bracket with nothing after it.  // OK
        (LB meta) :: [] ->
            Done
                { state
                    | committed = errorMessage "[...?" :: state.committed
                    , stack = []
                    , tokenIndex = 0
                    , numberOfTokens = 0
                    , messages = Helpers.prependMessage "That left bracket needs something after it" state.messages
                }

        -- extra right bracket
        (RB meta) :: rest ->
            Loop
                { state
                    | committed = errorMessage " extra ]?" :: state.committed
                    , stack = []
                    , tokenIndex = meta.index + 1
                    , messages = Helpers.prependMessage "Extra right bracket(s)" state.messages
                }

        -- dollar sign with no closing dollar sign
        (MathToken meta) :: rest ->
            let
                content =
                    Token.toString rest

                message =
                    if content == "" then
                        "$?$"

                    else
                        "$ "
            in
            Loop
                { state
                    | committed = errorMessage message :: state.committed
                    , stack = []
                    , tokenIndex = meta.index + 1
                    , numberOfTokens = 0
                    , messages = Helpers.prependMessage "opening dollar sign needs to be matched with a closing one" state.messages
                }

        -- backtick with no closing backtick
        (CodeToken meta) :: rest ->
            let
                content =
                    Token.toString rest

                message =
                    if content == "" then
                        "`?`"

                    else
                        "` "
            in
            Loop
                { state
                    | committed = errorMessageBold message :: state.committed
                    , stack = []
                    , tokenIndex = meta.index + 1
                    , numberOfTokens = 0
                    , messages = Helpers.prependMessage "opening backtick needs to be matched with a closing one" state.messages
                }

        _ ->
            recoverFromError1 state


errorSuffix rest =
    case rest of
        [] ->
            "]?"

        (W _ _) :: [] ->
            "]?"

        _ ->
            ""


recoverFromError1 : State -> Step State State
recoverFromError1 state =
    let
        k =
            Symbol.balance <| Symbol.convertTokens (List.reverse state.stack)

        newStack =
            List.repeat k (RB dummyLoc) ++ state.stack

        newSymbols =
            Symbol.convertTokens (List.reverse newStack)

        reducible =
            M.reducible newSymbols
    in
    if reducible then
        Done <|
            addErrorMessage " ]? " <|
                reduceState <|
                    { state
                        | stack = newStack
                        , tokenIndex = 0
                        , numberOfTokens = List.length newStack
                        , committed = errorMessage "[" :: state.committed
                        , messages = Helpers.prependMessage ("Unmatched brackets: added " ++ String.fromInt k ++ " right brackets") state.messages
                    }

    else
        Done
            { state
                | committed =
                    bracketError k
                        -- :: Expr "blue" [ Text (" " ++ Token.toString state.tokens) dummyLoc ] dummyLoc
                        :: state.committed
                , messages = Helpers.prependMessage (bracketErrorAsString k) state.messages
            }


bracketError : Int -> Expr
bracketError k =
    if k < 0 then
        let
            brackets =
                List.repeat -k "]" |> String.join ""
        in
        errorMessage <| " " ++ brackets ++ " << Too many right brackets (" ++ String.fromInt -k ++ ")"

    else
        let
            brackets =
                List.repeat k "[" |> String.join ""
        in
        errorMessage <| " " ++ brackets ++ " << Too many left brackets (" ++ String.fromInt k ++ ")"


bracketErrorAsString : Int -> String
bracketErrorAsString k =
    if k < 0 then
        "Too many right brackets (" ++ String.fromInt -k ++ ")"

    else
        "Too many left brackets (" ++ String.fromInt k ++ ")"



-- HELPERS


dummyTokenIndex =
    0


dummyLoc =
    { begin = 0, end = 0, index = dummyTokenIndex }



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

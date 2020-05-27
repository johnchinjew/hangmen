module Main exposing (..)

import Alphabet exposing (Alphabet)
import Browser
import Debug
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import Json.Decode as Decode
import Pin exposing (Pin)
import Ports
import Random
import Regex exposing (Regex)
import Session exposing (Session)
import Socket
import Time



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- MODEL


type Model
    = Home HomeData
    | Lobby LobbyData
    | Game GameData
    | GameOver GameOverData


type alias HomeData =
    { start : Start
    , pin : String
    , playerPin : String
    , name : String
    , session : Maybe Session
    , error : Bool
    , randomness : Int
    }


type alias LobbyData =
    { session : Session
    , playerPin : String
    , word : String
    , hotJoining : Bool
    , connectivityIssues : Bool
    , error : Bool
    }


type alias GameData =
    { session : Session
    , playerPin : String
    , guessWord : String
    , timeLeft : Int
    }


type alias GameOverData =
    { session : Maybe Session
    , prevSession : Session
    , playerPin : String
    , name : String
    }


type Start
    = Create
    | Join


init : () -> ( Model, Cmd Msg )
init _ =
    ( Home <| HomeData Create "" "" "" Nothing False 0
    , Random.generate Randomness (Random.int 0 1)
    )



-- UPDATE


type Msg
    = NoOp
      -- HOME
    | Randomness Int
    | ConnectSuccessful String
    | PickStart Start
    | ChangedPin String
    | ChangedName String
    | ClickedStart
    | JoinSuccessful String
      -- LOBBY
    | ChangedWord String
    | ClickedSetWord
    | ClickedReady 
      -- GAME
    | ChangedGuessWord String
    | ClickedGuessLetter String
    | ClickedGuessWord String String
    | Tick Time.Posix
      -- GAMEOVER
    | ClickedMainMenu
    | ClickedPlayAgain
    | RejoinSuccessful String
      -- SERVER
    | OnGameUpdate Session


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( NoOp, _ ) ->
            ( model, Cmd.none )

        -- HOME
        ( Randomness int, Home h ) ->
            ( Home { h | randomness = int }, Cmd.none )

        ( ConnectSuccessful playerPin, Home h ) -> 
            ( Home { h | playerPin = playerPin } |> Debug.log "recieved player pin!"
            , Cmd.none )

        ( PickStart start, Home h ) ->
            ( Home { h | start = start, error = False }, Cmd.none )

        ( ChangedPin pin, Home h ) ->
            ( Home { h | pin = pin, error = False }, Cmd.none )

        ( ChangedName name, Home h ) ->
            ( Home { h | name = name, error = False }, Cmd.none )

        ( ClickedStart, Home h ) ->
            if valid h then
                ( Home { h | error = False }
                , case h.start of
                    Create ->
                        Socket.emitCreateGame h.name

                    Join ->
                        Socket.emitJoinGame h.pin h.name
                )

            else
                ( Home { h | error = True }, Cmd.none )

        -- ( JoinSuccessful playerPin, Home h ) ->
        --     case h.session of
        --         Nothing ->
        --             ( Home { h | playerPin = playerPin }
        --             , Cmd.none
        --             )

        --         Just session ->
        --             ( Lobby (LobbyData session playerPin "" (not session.isLobby) False False)
        --             , Cmd.none
        --             )

        ( OnGameUpdate game, Home h ) ->
            if Pin.valid h.playerPin then
                ( Lobby (LobbyData game h.playerPin "" (not game.isLobby) False False) |> Debug.log "received game!"
                , Cmd.none
                )

            else
                ( Home { h | session = Just game } |> Debug.log "invalid player pin!"
                , Cmd.none
                )

        -- LOBBY
        ( ChangedWord word, Lobby l ) ->
            ( Lobby { l | word = word }, Cmd.none )

        ( ClickedSetWord, Lobby l ) ->
            if validWord l.word then
                ( Lobby { l | hotJoining = False, error = False, word = "" }
                , Socket.emitSetWord <| String.toLower l.word
                -- , Socket.emitStartGame <| String.toLower l.word
                )

            else
                ( Lobby { l | error = True }
                , Cmd.none
                )

        ( ClickedReady, Lobby l ) ->
            if validWord <| Session.playerWord l.playerPin l.session then
                ( model, Socket.emitStartGame )

            else
                ( Lobby { l | error = True }
                , Cmd.none )
            

        ( OnGameUpdate game, Lobby l ) ->
            if not l.hotJoining && not game.isLobby then
                ( Game (GameData game l.playerPin "" 30) |> Debug.log "received game!"
                , Cmd.none
                )

            else
                ( Lobby { l | session = game } |> Debug.log "received game!"
                , Cmd.none
                )

        -- GAME
        ( ChangedGuessWord guessWord, Game g ) ->
            ( Game { g | guessWord = guessWord }, Cmd.none )

        ( ClickedGuessLetter letter, Game g ) ->
            ( model, Socket.emitGuessLetter letter )

        ( ClickedGuessWord pin word, Game g ) ->
            ( model, Socket.emitGuessWord pin <| String.toLower word )

        ( OnGameUpdate game, Game g ) ->
            case Session.status game of
                Session.Playing ->
                    ( Game { g | session = game } |> Debug.log "received game!"
                    , Cmd.none
                    )

                _ ->
                    let
                        playerName =
                            case Dict.get g.playerPin g.session.players of
                                Just player ->
                                    player.name

                                Nothing ->
                                    "<ERROR> Unable to retrieve player name"
                    in
                    ( GameOver (GameOverData Nothing game g.playerPin playerName) |> Debug.log "recieved game!"
                    , Cmd.none
                    )

        ( Tick time, Game g ) ->
            if Session.turn g.session == Just g.playerPin && g.timeLeft == 1 then 
                ( Game { g | timeLeft = 30 }
                , Socket.emitSkipTurn )

            else 
                ( Game { g | timeLeft = g.timeLeft - 1 }
                , Cmd.none )

        ( ClickedMainMenu, GameOver g ) ->
            ( Home <| HomeData Create "" "" "" Nothing False 0
            , Random.generate Randomness (Random.int 0 1)
            )

        ( ClickedPlayAgain, GameOver g ) ->
            ( model, Socket.emitJoinGame g.prevSession.pin g.name )

        ( OnGameUpdate game, GameOver g ) -> 
            ( Lobby (LobbyData game g.playerPin "" (not game.isLobby) False False)
            , Cmd.none 
            )

        -- ( JoinSuccessful playerPin, GameOver g ) ->
        --     case g.session of
        --         Nothing ->
        --             ( GameOver { g | playerPin = playerPin }
        --             , Cmd.none
        --             )

        --         Just session ->
        --             ( Lobby (LobbyData session playerPin "" (not session.isLobby) False False)
        --             , Cmd.none
        --             )

        -- ( OnGameUpdate game, GameOver g ) ->
        --     ( GameOver { g | session = Just game } |> Debug.log "received game!"
        --     , Cmd.none
        --     )

        -- CATCHALL
        ( _, _ ) ->
            update NoOp model


valid : HomeData -> Bool
valid h =
    let
        nameLength =
            1 <= String.length h.name && String.length h.name <= 30

        -- Leave this here until we use it into the Lobby UI
        -- wordLength =
        --     2 <= String.length h.word && String.length h.word <= 30
        -- alphabeticWord =
        --     alphabetic h.word
        validPin =
            h.start == Create || Pin.fromString h.pin /= Nothing
    in
    nameLength && validPin


validWord : String -> Bool
validWord word =
    let
        wordLength =
            2 <= String.length word && String.length word <= 30

        alphabeticWord =
            alphabetic word
    in
    wordLength && alphabeticWord


letters : Regex
letters =
    Maybe.withDefault Regex.never <| Regex.fromString "^[a-zA-Z]+$"


alphabetic : String -> Bool
alphabetic string =
    (String.length <| Regex.replaceAtMost 1 letters (\match -> "") string) == 0



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.fromSocket
            (\value ->
                case Decode.decodeValue Session.decode value of
                    Ok session ->
                        OnGameUpdate session

                    Err _ ->
                        NoOp |> Debug.log "failed to decode session"
            )
        , Ports.fromSocket
            (\playerPin ->
                case Decode.decodeValue Decode.string playerPin of
                    Ok playerPin_ ->
                        ConnectSuccessful playerPin_

                    Err _ ->
                        NoOp |> Debug.log "failed to decode playerPin"
            )
        , Time.every 1000 Tick
        ]
    



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "Hangmen"
    , body =
        case model of
            Home h ->
                [ Html.h1 [] [ Html.text "Hangmen" ]
                , Html.p []
                    [ Html.text "Scalable hangman" ]
                , Html.div []
                    [ Html.input
                        [ Attributes.type_ "radio"
                        , Attributes.name "start"
                        , Attributes.id "create"
                        , Attributes.checked <| h.start == Create
                        , Events.onInput <| \_ -> PickStart Create
                        ]
                        []
                    , Html.label [ Attributes.for "create" ] [ Html.text "Create game" ]
                    ]
                , Html.div []
                    [ Html.input
                        [ Attributes.type_ "radio"
                        , Attributes.name "start"
                        , Attributes.id "join"
                        , Attributes.checked <| h.start == Join
                        , Events.onInput <| \_ -> PickStart Join
                        ]
                        []
                    , Html.label [ Attributes.for "join" ] [ Html.text "Join existing game" ]
                    ]
                ]
                    ++ (if h.start == Join then
                            [ Html.p []
                                [ Html.text "Game PIN: "
                                , Html.input
                                    [ Attributes.placeholder "Enter game PIN"
                                    , Attributes.value h.pin
                                    , Events.onInput ChangedPin
                                    ]
                                    []
                                ]
                            ]

                        else
                            []
                       )
                    ++ [ Html.p []
                            [ Html.text "Name: "
                            , Html.input
                                [ Attributes.placeholder "Enter name"
                                , Attributes.value h.name
                                , Events.onInput ChangedName
                                ]
                                []
                            ]
                       ]
                    ++ (if h.error then
                            [ Html.p [] [ Html.text "Invalid input. Fix and try again." ] ]

                        else
                            []
                       )
                    ++ [ Html.button [ Events.onClick ClickedStart ] [ Html.text "Start" ]
                       , Html.p []
                            [ Html.text <|
                                if h.randomness == 1 then
                                    "Created by Eero Gallano and John Chin-Jew."

                                else
                                    "Created by John Chin-Jew and Eero Gallano."
                            ]
                       ]

            Lobby l ->
                (if l.connectivityIssues then
                    [ Html.h2 [] [ Html.text "Experiencing connectivity issues..." ] ]

                 else
                    []
                )
                    ++ (if l.session.isLobby then
                            [ Html.h2 [] [ Html.text "Lobby" ]
                            , viewGamePin l.session.pin
                            , Html.h3 []
                                [ Html.text "Players:" ]
                            , Html.div []
                                (List.map
                                    (\player ->
                                        Html.p []
                                            [ Html.text <|
                                                ((if not player.ready then
                                                    "\u{1F914}"

                                                else
                                                    "👍"
                                                )
                                                ++ "  "
                                                ++ player.name
                                                )
                                            ]
                                    )
                                    (Dict.values l.session.players)
                                )
                            , Html.p []
                                [ Html.input
                                    [ Attributes.placeholder "Enter your word"
                                    , Attributes.value l.word
                                    , Events.onInput ChangedWord
                                    , Attributes.disabled <| Session.playerReady l.playerPin l.session 
                                    ]
                                    []
                                , Html.button
                                    [ Events.onClick ClickedSetWord
                                    , Attributes.style "margin-left" "0.5rem"
                                    , Attributes.style "border-color" <|
                                        if Session.playerReady l.playerPin l.session then 
                                            "whitesmoke"
                                        
                                        else 
                                            "lightgrey"
                                    , Attributes.style "color" <|
                                        if Session.playerReady l.playerPin l.session then
                                            "whitesmoke"

                                        else 
                                            "black"
                                    , Attributes.disabled <| Session.playerReady l.playerPin l.session ]
                                    [ Html.text "Set word" ]
                                , Html.button
                                    [ Events.onClick ClickedReady, Attributes.style "margin-left" "0.5rem" ]
                                    [ Html.text <|
                                        (if not <| Session.playerReady l.playerPin l.session then
                                            "Ready" 
                                        
                                        else 
                                            "Unready")]
                                ]
                            ]
                                ++ (if l.error then
                                        [ Html.p [] [ Html.text "Invalid word." ] ]

                                    else
                                        []
                                   )
                                ++ (let
                                        playerWord = Session.playerWord l.playerPin l.session
                                    in
                                    [ Html.p [] <|
                                        if validWord playerWord then 
                                            [ Html.text "Your word: "
                                            , Html.span 
                                                [ Attributes.class "spoiler" ]
                                                [ Html.text playerWord ]
                                            ]

                                        else 
                                            [ Html.text "You have not set a word yet." ]
                                    ])

                        else
                            [ Html.h2 []
                                [ Html.text "Game in-session! Hotjoining..." ]
                            , Html.p []
                                [ Html.input
                                    [ Attributes.placeholder "Enter your word"
                                    , Attributes.value l.word
                                    , Events.onInput ChangedWord
                                    ]
                                    []
                                ]
                            , Html.button
                                [ Events.onClick ClickedSetWord ]
                                [ Html.text "Join game" ]
                            ]
                                ++ (if l.error then
                                        [ Html.p [] [ Html.text "Invalid word." ] ]

                                    else
                                        []
                                   )
                       )

            Game g ->
                let
                    isMyTurn =
                        Session.turn g.session == Just g.playerPin
                in
                [ Html.h2 []
                    [ let
                        name =
                            case Session.turn g.session of
                                Just turn ->
                                    Session.playerName turn g.session

                                Nothing ->
                                    "Unknown"
                      in
                      Html.text (name ++ "'s turn!")
                    ]
                , Html.p [] 
                    [ Html.text "Your word: " 
                    , Html.span 
                        [ Attributes.class "spoiler" ]
                        [ Html.text <| Session.playerWord g.playerPin g.session ]
                    ]
                , viewGamePin g.session.pin
                , viewPlayers g
                , Html.p 
                    (
                    [ Attributes.style "margin" "0.5rem 0"
                    , Attributes.style "padding" "0.5rem 1rem"
                    , Attributes.class "notice"
                    ] 
                    ++ (if isMyTurn then 
                            [ Attributes.style "background" "#FFE082" ] 
                        else 
                            [])
                    )
                    [ Html.text <|
                        (if isMyTurn then 
                            "It's your turn! Guess a letter below OR guess a word." 
                        else 
                            "Wait for your turn..." )
                        ++ "    " 
                        ++ String.fromInt g.timeLeft ++ "s left!"
                        
                    ]
                ]
                    -- ++ (if isMyTurn then
                    --         [ Html.p
                    --             [ Attributes.style "margin" "0.5rem 0"
                    --             , Attributes.style "padding" "0.5rem 1rem"
                    --             , Attributes.style "background" "#FFE082"
                    --             ]
                    --             [ Html.text "It's your turn! Guess a letter below OR guess a word." ]
                    --         ]

                    --     else
                    --         [ ]
                    --    )
                    ++ [ viewAlphabet g ]
                    ++ (if isMyTurn then
                            [ Html.p []
                                [ Html.text "Guess word (Sudden Death): "
                                , Html.input
                                    [ Events.onInput ChangedGuessWord, Attributes.value g.guessWord ]
                                    []
                                ]
                            ]

                        else
                            []
                       )

            GameOver g ->
                [ Html.h2 []
                    [ Html.text <|
                        case Session.status g.prevSession of
                            Session.Draw ->
                                "Draw!"

                            Session.Winner playerPin ->
                                let
                                    playerName =
                                        case Dict.get playerPin g.prevSession.players of
                                            Just player ->
                                                player.name

                                            Nothing ->
                                                "<ERROR> Unable to retrieve player name"
                                in
                                playerName ++ " wins!"

                            _ ->
                                "<ERROR> Invalid end state"
                    ]
                , Html.div []
                    (List.map
                        (\player ->
                            Html.p
                                [ Attributes.style "color"
                                    (if player.alive then
                                        "black"

                                     else
                                        "gray"
                                    )
                                ]
                                [ Html.text
                                    ((if not player.alive then
                                        "💀"

                                      else
                                        "🥳"
                                     )
                                        ++ "  "
                                        ++ player.name
                                        ++ ": "
                                        ++ player.word
                                    )
                                ]
                        )
                        (Dict.values g.prevSession.players)
                    )
                , Html.button
                    [ Events.onClick ClickedPlayAgain
                    , Attributes.style "margin-right" "0.4rem"
                    ]
                    [ Html.text "Play again!" ]
                , Html.button [ Events.onClick ClickedMainMenu ] [ Html.text "Main menu" ]
                ]
    }


viewGamePin : String -> Html Msg
viewGamePin pin =
    Html.h3
        [ Attributes.style "position" "absolute"
        , Attributes.style "top" "0.4rem"
        , Attributes.style "right" "0"
        , Attributes.style "margin" "2rem"
        ]
        [ Html.text <| "Game PIN: " ++ pin ]


viewPlayers : GameData -> Html Msg
viewPlayers g =
    Html.div []
        (List.map
            (\player ->
                Html.p
                    [ Attributes.style "color"
                        (if player.alive then
                            "black"

                         else
                            "gray"
                        )
                    ]
                    ([ Html.text
                        ((if not player.alive then
                            "💀"

                          else if Session.turn g.session == Just player.pin then
                            "\u{1F914}"

                          else
                            "🙂"
                         )
                            ++ " "
                            ++ player.name
                            ++ ": "
                            ++ (if not player.alive then
                                    player.word

                                else if not player.ready then
                                    "joining..."

                                else
                                    wordSoFar player.word g.session.alphabet
                               )
                        )
                     ]
                        ++ (if
                                g.playerPin
                                    /= player.pin
                                    && player.ready
                                    && player.alive
                            then
                                [ Html.button
                                    [ Attributes.style "margin-left" "10px"
                                    , Attributes.disabled <|
                                        Session.turn g.session
                                            /= Just g.playerPin
                                            || (case Session.status g.session of
                                                    Session.Playing ->
                                                        False

                                                    _ ->
                                                        True
                                               )
                                    , Events.onClick (ClickedGuessWord player.pin g.guessWord)
                                    ]
                                    [ Html.text "⚔️" ]
                                ]

                            else
                                []
                           )
                    )
            )
            (Dict.values g.session.players)
        )


wordSoFar : String -> Alphabet -> String
wordSoFar word alphabet =
    word
        |> String.map
            (\char ->
                case Dict.get (String.fromChar char) alphabet.letters of
                    Just isSet ->
                        if isSet then
                            char

                        else
                            '_'

                    Nothing ->
                        '_'
            )
        |> String.toList
        |> List.map String.fromChar
        |> String.join " "


viewAlphabet : GameData -> Html Msg
viewAlphabet g =
    Html.div
        [ Attributes.style "max-width" "490px"
        ]
        (List.map
            (\letter ->
                Html.button
                    ([ Attributes.disabled
                        (Tuple.second letter
                            || Session.turn g.session
                            /= Just g.playerPin
                            || (case Session.status g.session of
                                    Session.Playing ->
                                        False

                                    _ ->
                                        True
                               )
                        )
                     , Attributes.style "margin" "0.5rem"
                     , Attributes.style "font-size" "0.85rem"
                     ]
                        ++ (if Tuple.second letter then
                                [ Attributes.style "text-decoration" "line-through"
                                , Attributes.style "border-color" "whitesmoke"
                                , Attributes.style "color" "whitesmoke"
                                ]

                            else
                                []
                           )
                        ++ (if Session.turn g.session == Just g.playerPin then
                                [ Events.onClick (ClickedGuessLetter (Tuple.first letter)) ]

                            else
                                []
                           )
                    )
                    [ Html.text <| Tuple.first letter ]
            )
            (Dict.toList g.session.alphabet.letters)
        )

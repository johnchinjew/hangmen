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
import Regex exposing (Regex)
import Session exposing (Session)
import Socket



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


type alias HomeData =
    { start : Start
    , pin : String
    , playerPin : String
    , name : String
    , session : Maybe Session
    , error : Bool
    }


type alias LobbyData =
    { session : Session
    , playerPin : String
    , word : String
    , hotJoining : Bool
    , connectivityIssues : Bool
    }


type alias GameData =
    { session : Session
    , playerPin : String
    , guessWord : String }


type Start
    = Create
    | Join


init : () -> ( Model, Cmd Msg )
init _ =
    ( Home <| HomeData Create "" "" "" Nothing False
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
      -- HOME
    | PickStart Start
    | ChangedPin String
    | ChangedName String
    | ClickedStart
    | JoinSuccessful String
      -- LOBBY
    | ChangedWord String
    | ClickedStartGame
      -- GAME
    | ChangedGuessWord String
    | ClickedGuessLetter String
    | ClickedGuessWord String String
      -- SERVER
    | OnGameUpdate Session


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( NoOp, _ ) ->
            ( model, Cmd.none )

        -- HOME
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

        ( JoinSuccessful playerPin, Home h ) ->
            case h.session of
                Nothing ->
                    ( Home { h | playerPin = playerPin }
                    , Cmd.none
                    )

                Just session ->
                    ( Lobby (LobbyData session playerPin "" (not session.isLobby) False)
                    , Cmd.none
                    )

        ( OnGameUpdate game, Home h ) ->
            if Pin.valid h.playerPin then
                ( Lobby (LobbyData game h.playerPin "" (not game.isLobby) False) |> Debug.log "received game!"
                , Cmd.none
                )

            else
                ( Home { h | session = Just game } |> Debug.log "received game!"
                , Cmd.none
                )

        -- LOBBY
        ( ChangedWord word, Lobby l ) ->
            ( Lobby { l | word = word }, Cmd.none )

        ( ClickedStartGame, Lobby l ) ->
            ( Lobby { l | hotJoining = False }
            , Socket.emitStartGame l.word 
            )

        ( OnGameUpdate game, Lobby l ) ->
            if not l.hotJoining && not game.isLobby then
                ( Game (GameData game l.playerPin "") |> Debug.log "received game!"
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
            ( model, Socket.emitGuessWord pin word )

        ( OnGameUpdate game, Game g ) ->
            ( Game { g | session = game } |> Debug.log "received game!"
            , Cmd.none
            )

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
                        JoinSuccessful playerPin_

                    Err _ ->
                        NoOp |> Debug.log "failed to decode playerPin"
            )
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

                       --    , Html.p []
                       --         [ Html.text "Word: "
                       --         , Html.input
                       --             [ Attributes.placeholder "Choose word"
                       --             , Attributes.value h.word
                       --             , Events.onInput ChangedWord
                       --             ]
                       --             []
                       --         ]
                       ]
                    ++ (if h.error then
                            [ Html.p [] [ Html.text "Invalid input. Fix and try again." ] ]

                        else
                            []
                       )
                    ++ [ Html.button [ Events.onClick ClickedStart ] [ Html.text "Start" ]
                       , Html.p [] [ Html.text "Created by Eero Gallano and John Chin-Jew." ]
                       ]

            Lobby l ->
                (if l.connectivityIssues then
                    [ Html.h2 [] [ Html.text "Experiencing connectivity issues..." ] ]

                 else
                    []
                )
                    ++ (if l.session.isLobby then
                        [ Html.h2 []
                            [ Html.text ("Lobby: " ++ l.session.pin) ]
                       , Html.h3 []
                            [ Html.text "Players:" ]
                       , Html.ul []
                            (List.map
                                (\player ->
                                    Html.li []
                                        [ Html.text <|
                                            player.name
                                                ++ ": "
                                                ++ (if player.ready then
                                                        "Ready"

                                                    else
                                                        "Not ready"
                                                   )
                                        ]
                                )
                                (Dict.values l.session.players)
                            )
                       , Html.p []
                            [ Html.text "Pick word:"
                            , Html.input
                                [ Events.onInput ChangedWord
                                ]
                                []
                            , Html.button
                                [ Events.onClick ClickedStartGame ]
                                [ Html.text "Start game" ]
                            ]
                       ]
                    else 
                        [ Html.p [] 
                            [ Html.text "Pick word: "
                            , Html.input
                                [ Events.onInput ChangedWord
                                ]
                                []
                            ]
                            , Html.button
                                [ Events.onClick ClickedStartGame ]
                                [ Html.text "Join game"]
                        ]
                    )

            Game g ->
                [ Html.h2 []
                    [ let
                        name =
                            case Session.turn g.session of
                                Just turn ->
                                    Session.playerName turn g.session

                                Nothing ->
                                    "Unknown"
                      in
                      case Session.status g.session of
                        Session.Winner pid ->
                            Html.text (name ++ " won!")

                        Session.Draw ->
                            Html.text "Draw!"

                        Session.Playing ->
                            Html.text (name ++ "'s turn!")
                    ]
                ]
                    ++ (case Session.status g.session of
                            Session.Playing ->
                                []

                            _ ->
                                [ Html.button [ Events.onClick NoOp ] [ Html.text "Play again!" ]
                                , Html.button [ Events.onClick NoOp ] [ Html.text "Main menu"]
                                ]

                       )
                    ++ [ viewPlayers g
                       , viewAlphabet g
                       , Html.p [] 
                            [ Html.text "Guess word: "
                            , Html.input 
                                [ Events.onInput ChangedGuessWord ]
                                []
                            ]
                       ]
    }


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
                            "gray")
                    ] 
                    ([ Html.text
                        (   
                            (if not player.alive then
                                "💀"
                            else if Session.turn g.session == Just player.pin then 
                                "🤔"
                            else 
                                "🙂"
                            )
                            ++ " "
                            ++ player.name
                            ++ ": "
                            ++ 
                            (if not player.alive then 
                                player.word
                            else 
                                wordSoFar player.word g.session.alphabet
                            )
                        )
                    ]
                    ++ (if g.playerPin /= player.pin then
                        [ Html.button 
                            [ Attributes.style "margin-left" "10px" 
                            , Attributes.disabled 
                                <| Session.turn g.session
                                /= Just g.playerPin
                                || not player.alive
                                || (case Session.status g.session of
                                        Session.Playing ->
                                            False
                                            
                                        _ ->
                                            True
                                    )
                            , Events.onClick (ClickedGuessWord player.pin g.guessWord)
                            ]
                            [ Html.text "Sudden Death"]
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
    String.map
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
        word


viewAlphabet : GameData -> Html Msg
viewAlphabet g =
    Html.p []
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
                     ]
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

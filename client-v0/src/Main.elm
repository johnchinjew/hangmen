module Main exposing (..)

import Alphabet exposing (Alphabet)
import Api
import Browser
import Browser.Navigation as Navigation
import Debug
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import Http
import Json.Encode as Encode
import Player exposing (Player)
import Route exposing (Route)
import Session exposing (Session)
import Time
import Url exposing (Url)



-- MAIN


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
    -- | Join JoinData
    -- | Lobby LobbyData
    -- | Game GameData


type alias HomeData =
    { gameCreateFailed : Bool }


-- type alias JoinData =
--     { sid : String, name : String, joinFailed : Bool }


-- type alias LobbyData =
--     { session : Session, pid : String, word : String, pollingFailed : Bool }


-- type alias GameData =
--     { session : Session, pid : String, pollingFailed : Bool }


init : () -> ( Model, Cmd Msg )
init _ = 
    ( case Route.parse url of
        Route.Root maybeSid ->
            case maybeSid of
                Just sid ->
                    Join { sid = sid, name = "", joinFailed = False }

                Nothing ->
                    Home { gameCreateFailed = False }

        Route.Invalid ->
            Home { gameCreateFailed = False }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
      -- Home
    | ClickedCreateGame
    | ReceivedSid (Result Http.Error String)
      -- JOIN
    | EditName String
    | ClickedJoinGame
    | ReceivedPid (Result Http.Error String)
    | ReceivedFirstSession String (Result Http.Error Session)
      -- LOBBY
    | EditWord String
    | ClickedStartGame
      -- GAME
    | ClickedGuessLetter String
    | ClickedPlayAgain
      -- POLLING
    | PollTick
    | ReceivedSession (Result Http.Error Session)
    | ReceivedWhatever (Result Http.Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( NoOp, _ ) ->
            ( model, Cmd.none )

        -- Home
        ( ClickedCreateGame, Home _ ) ->
            ( model
            , Api.postNewSession ReceivedSid
            )

        ( ReceivedSid result, Home w ) ->
            case result of
                Ok sid ->
                    ( model, Navigation.load (Route.withQuerySid sid) )

                Err _ ->
                    ( Home { w | gameCreateFailed = True }, Cmd.none )

        -- JOIN
        ( EditName name, Join j ) ->
            ( Join { j | name = name }, Cmd.none )

        ( ClickedJoinGame, Join j ) ->
            ( model, Api.postJoinSession { sid = j.sid, name = j.name } ReceivedPid )

        ( ReceivedPid result, Join j ) ->
            case result of
                Ok pid ->
                    ( model, Api.postGetState { sid = j.sid } (ReceivedFirstSession pid) )

                Err _ ->
                    ( Join { j | joinFailed = True }, Cmd.none )

        ( ReceivedFirstSession pid result, Join j ) ->
            case result of
                Ok session ->
                    ( Lobby { session = session, pid = pid, word = "", pollingFailed = False }, Cmd.none )

                Err _ ->
                    ( Join { j | joinFailed = True }, Cmd.none )

        -- LOBBY
        ( EditWord word, Lobby l ) ->
            ( Lobby { l | word = String.toLower word }, Cmd.none )

        ( ClickedStartGame, Lobby l ) ->
            ( Lobby l, Api.postSetWord { sid = l.session.sid, pid = l.pid, word = l.word } ReceivedWhatever )

        -- LOBBY POLLING
        ( PollTick, Lobby l ) ->
            ( model, Api.postGetState { sid = l.session.sid } ReceivedSession )

        ( ReceivedSession result, Lobby l ) ->
            case result of
                Ok session ->
                    ( if session.isLobby then
                        Lobby { l | session = session }

                      else
                        Game { session = session, pid = l.pid, pollingFailed = False }
                    , Cmd.none
                    )

                Err _ ->
                    ( Lobby { l | pollingFailed = True }, Cmd.none )

        -- GAME
        ( ClickedGuessLetter letter, Game g ) ->
            ( model, Api.postGuessLetter { sid = g.session.sid, letter = letter } ReceivedWhatever )

        ( ClickedPlayAgain, Game g ) ->
            ( Lobby
                { session = g.session
                , pid = g.pid
                , word = ""
                , pollingFailed = False
                }
            , Cmd.none
            )

        -- GAME POLLING
        ( PollTick, Game g ) ->
            ( model, Api.postGetState { sid = g.session.sid } ReceivedSession )

        ( ReceivedSession result, Game g ) ->
            case result of
                Ok session ->
                    ( Game { g | session = session }, Cmd.none )

                Err _ ->
                    ( Game { g | pollingFailed = True }, Cmd.none )

        -- POLLING
        ( ReceivedWhatever _, _ ) ->
            update NoOp model

        -- CATCHALL
        ( _, _ ) ->
            update NoOp model



-- SUBSCRIPTIONS


pollInterval : Float
pollInterval =
    700


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Lobby _ ->
            Time.every pollInterval (\_ -> PollTick)

        Game g ->
            case Session.status g.session of
                Session.Playing ->
                    Time.every pollInterval (\_ -> PollTick)

                _ ->
                    Sub.none

        _ ->
            Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "Hangmen"
    , body =
        case model of
            Home w ->
                (if w.gameCreateFailed then
                    [ Html.h2 [] [ Html.text "Failed to create game! Please try again later." ] ]

                 else
                    []
                )
                    ++ [ Html.h1 [] [ Html.text "Hangmen" ]
                       , Html.button
                            [ Events.onClick ClickedCreateGame ]
                            [ Html.text "Create game" ]
                       ]

            Join j ->
                (if j.joinFailed then
                    [ Html.h2 [] [ Html.text "Could not join session! Please try again." ] ]

                 else
                    []
                )
                    ++ [ Html.text "Enter name:"
                       , Html.input [ Events.onInput EditName ] []
                       , Html.button
                            [ Events.onClick ClickedJoinGame ]
                            [ Html.text "Join game" ]
                       ]

            Lobby l ->
                (if l.pollingFailed then
                    [ Html.h2 [] [ Html.text "Experiencing connectivity issues..." ] ]

                 else
                    []
                )
                    ++ [ Html.h2 []
                            [ Html.text ("Lobby: " ++ Route.shareLink l.session.sid) ]
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
                                [ Events.onInput EditWord
                                ]
                                []
                            , Html.button
                                [ Events.onClick ClickedStartGame ]
                                [ Html.text "Start game" ]
                            ]
                       ]

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
                                [ Html.button [ Events.onClick ClickedPlayAgain ] [ Html.text "Play again!" ] ]
                       )
                    ++ [ viewPlayers g
                       , viewAlphabet g
                       ]
    }


viewPlayers : GameData -> Html Msg
viewPlayers g =
    Html.div []
        (List.map
            (\player ->
                Html.p []
                    [ Html.text
                        (player.name
                            ++ ": "
                            ++ wordSoFar player.word g.session.alphabet
                        )
                    ]
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
                            /= Just g.pid
                            || (case Session.status g.session of
                                    Session.Playing ->
                                        False

                                    _ ->
                                        True
                               )
                        )
                     ]
                        ++ (if Session.turn g.session == Just g.pid then
                                [ Events.onClick (ClickedGuessLetter (Tuple.first letter)) ]

                            else
                                []
                           )
                    )
                    [ Html.text <| Tuple.first letter ]
            )
            (Dict.toList g.session.alphabet.letters)
        )

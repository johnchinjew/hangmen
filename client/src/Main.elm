module Main exposing (..)

import Api
import Browser
import Browser.Navigation as Navigation
import Debug
import Dict exposing (Dict)
import Html
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
    Browser.application
        { init = init
        , onUrlChange = \_ -> NoOp
        , onUrlRequest = \_ -> NoOp
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- MODEL


type Model
    = Welcome { gameCreateFailed : Bool }
    | Join { sid : String, name : String, joinFailed : Bool }
    | Lobby { session : Session, pid : String, word : String, pollingFailed : Bool }
    | Game


init : () -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init _ url _ =
    ( case Route.parse url of
        Route.Root maybeSid ->
            case maybeSid of
                Just sid ->
                    Join { sid = sid, name = "", joinFailed = False }

                Nothing ->
                    Welcome { gameCreateFailed = False }

        Route.Invalid ->
            Welcome { gameCreateFailed = False }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
      -- WELCOME
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
    | ReceivedWhatever (Result Http.Error ())
      -- POLLING
    | PollTick
    | ReceivedSession (Result Http.Error Session)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        -- WELCOME
        ( ClickedCreateGame, Welcome _ ) ->
            ( model
            , Api.postNewSession ReceivedSid
            )

        ( ReceivedSid result, Welcome w ) ->
            case result of
                Ok sid ->
                    ( model, Navigation.load (Route.withQuerySid sid) )

                Err _ ->
                    ( Welcome { w | gameCreateFailed = True }, Cmd.none )

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

        ( ReceivedWhatever _, Lobby l ) ->
            update NoOp model

        ( ReceivedSession result, Lobby l ) ->
            case result of
                Ok session ->
                    ( if session.isLobby then
                        Lobby { l | session = session }

                      else
                        Game
                    , Cmd.none
                    )

                Err _ ->
                    ( Lobby { l | pollingFailed = True }, Cmd.none )

        -- POLLING
        ( PollTick, Lobby l ) ->
            ( model, Api.postGetState { sid = l.session.sid } ReceivedSession )

        -- OTHER
        ( NoOp, _ ) ->
            ( model, Cmd.none )

        _ ->
            update NoOp model



-- SUBSCRIPTIONS


pollInterval : Float
pollInterval =
    1500


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Lobby _ ->
            Time.every pollInterval (\_ -> PollTick)

        _ ->
            Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "Hangmen"
    , body =
        case model of
            Welcome w ->
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
                    [ Html.h2 [] [ Html.text "Experiencing connectivity issue..." ] ]

                 else
                    []
                )
                    ++ [ Html.h2 []
                            [ Html.text "Lobby" ]
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

            Game ->
                [ Html.text "Not implemented" ]
    }

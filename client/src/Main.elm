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
import Route exposing (Route)
import State exposing (..)
import Time
import Url exposing (Url)
import Url.Builder



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


type alias Model =
    { screen : Screen
    , route : Route
    , alert : Maybe String
    , sid : Route.SessionId

    -- , player : PlayerState
    , pid : String
    , name : String
    , word : String
    , ready : Bool
    , alive : Bool
    , sessionState : SessionState
    , polling : Bool
    }


type Screen
    = WelcomeMenu
    | JoinMenu
    | LoadingMenu
    | LobbyMenu
    | ActiveGame
    | InvalidScreen


init : () -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init _ url _ =
    let
        route =
            Route.parse url
    in
    ( { screen =
            case route of
                Route.Root maybeSid ->
                    case maybeSid of
                        Just sid ->
                            JoinMenu

                        Nothing ->
                            WelcomeMenu

                Route.Invalid ->
                    InvalidScreen
      , route = route
      , alert = Nothing
      , sid =
            case route of
                Route.Root maybeSid ->
                    case maybeSid of
                        Just sid ->
                            sid

                        Nothing ->
                            "<NULL_SID>"

                Route.Invalid ->
                    "<NULL_SID>"

      --   , player =
      , pid = "<NULL_PID>"
      , name = "<NULL_NAME>"
      , word = "<NULL_WORD>"
      , ready = False
      , alive = True
      , sessionState =
            { sid = "<NULL_SID>"
            , players = Dict.fromList []
            , turnOrder = []
            , alphabet =
                { letters = Dict.fromList [] }
            , isLobby = True
            }
      , polling = False
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
    | ClickedCreateGame
    | ClickedJoinGame
    | ClickedSetWord
    | PollTick
    | ReceivedWhatever (Result Http.Error ())
    | ReceivedSessionId (Result Http.Error String)
    | ReceivedPlayerId (Result Http.Error String)
    | ReceivedSessionState (Result Http.Error SessionState)
    | ChangeName String
    | ChangeWord String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ClickedCreateGame ->
            ( model
            , Api.postNewSession ReceivedSessionId
            )

        ClickedJoinGame ->
            ( { model | screen = LoadingMenu, polling = True }
            , Api.postJoinSession { sid = model.sid, name = model.name } ReceivedPlayerId
            )

        ClickedSetWord ->
            ( { model | ready = True }
            , Api.postSetWord { sid = model.sid, pid = model.pid, word = model.word } ReceivedWhatever
            )

        PollTick ->
            ( model, Api.postGetState { sid = model.sid } ReceivedSessionState )

        ReceivedWhatever _ ->
            update NoOp model

        ReceivedSessionId result ->
            case result of
                Ok sid ->
                    ( model
                    , Navigation.load <|
                        Url.Builder.relative [] [ Url.Builder.string "sid" sid ]
                    )

                Err _ ->
                    ( { model | alert = Just "Failed to create session." }, Cmd.none )

        ReceivedPlayerId result ->
            case result of
                Ok pid ->
                    ( { model | pid = pid, screen = LoadingMenu, polling = True }
                    , Cmd.none
                    )

                Err _ ->
                    ( { model | alert = Just "Failed to join session." }, Cmd.none )

        ReceivedSessionState result ->
            case result of
                Ok state ->
                    ( { model
                        | screen =
                            if state.isLobby then
                                LobbyMenu

                            else
                                ActiveGame
                        , sessionState = state
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( { model | alert = Just "Failed to get session state." }, Cmd.none )

        ChangeName name ->
            ( { model | name = name }, Cmd.none )

        ChangeWord word ->
            ( { model | word = String.toLower word }, Cmd.none )



-- SUBSCRIPTION


pollInterval : Float
pollInterval =
    1500


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.polling then
        Time.every pollInterval (\_ -> PollTick)

    else
        Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "Hangmen"
    , body =
        case model.screen of
            WelcomeMenu ->
                let
                    maybeErrorMsg =
                        case model.alert of
                            Just msg ->
                                [ Html.h2 [] [ Html.text msg ] ]

                            Nothing ->
                                []
                in
                maybeErrorMsg
                    ++ [ Html.h1 [] [ Html.text "Hangmen" ]
                       , Html.button
                            [ Events.onClick ClickedCreateGame ]
                            [ Html.text "Create Game" ]
                       ]

            JoinMenu ->
                [ Html.text "Choose name: "
                , Html.input [ Events.onInput ChangeName ] []
                , Html.button
                    [ Events.onClick ClickedJoinGame ]
                    [ Html.text "Join Game" ]
                ]

            LoadingMenu ->
                [ Html.h2
                    []
                    [ Html.text "Joining..." ]
                ]

            LobbyMenu ->
                [ Html.h2 []
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
                                                "Not Ready"
                                           )
                                ]
                        )
                     <|
                        Dict.values model.sessionState.players
                    )
                , Html.p []
                    [ Html.text "Choose word:"
                    , Html.input
                        [ Events.onInput ChangeWord
                        ]
                        []
                    , Html.button
                        [ Events.onClick ClickedSetWord
                        ]
                        [ Html.text "Start game" ]
                    ]
                ]

            ActiveGame ->
                [ Html.h1 [] [ Html.text "Hangmen" ]
                , Html.h2 [] [ Html.text "Active game screen" ]
                ]

            InvalidScreen ->
                [ Html.h1 [] [ Html.text "404" ]
                ]
    }


renderSession : String -> SessionState -> Browser.Document Msg
renderSession name state =
    { title = "Hangmen"
    , body =
        [ Html.p []
            [ Html.text <|
                "name: "
                    ++ name
                    ++ " | state: "
                    ++ sessionStateToString state
            ]
        ]
    }

module Main exposing (..)

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
    , stateCache : SessionState
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
      , stateCache =
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
    | PostNewSession
    | PostJoinSession
    | PostGetState
    | PostSetWord
    | ReceivedSid (Result Http.Error String)
    | ReceivedPid (Result Http.Error String)
    | ReceivedState (Result Http.Error SessionState)
    | SetWord (Result Http.Error ())
    | ChangeName String
    | ChangeWord String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        PostNewSession ->
            ( model
            , Http.post
                { url = Url.Builder.relative [ "new-session" ] []
                , body = Http.emptyBody
                , expect = Http.expectString ReceivedSid
                }
            )

        PostJoinSession ->
            ( { model | screen = LoadingMenu, polling = True }
            , Http.post
                { url = Url.Builder.relative [ "join-session" ] []
                , body =
                    Http.jsonBody <|
                        Encode.object
                            [ ( "sid", Encode.string model.sid )
                            , ( "name", Encode.string model.name )
                            ]
                , expect = Http.expectString ReceivedPid
                }
            )

        PostGetState ->
            ( model
            , Http.post
                { url = Url.Builder.relative [ "get-state" ] []
                , body =
                    Http.jsonBody <|
                        Encode.object [ ( "sid", Encode.string model.sid ) ]
                , expect = Http.expectJson ReceivedState decodeSessionState
                }
            )

        PostSetWord ->
            ( { model | ready = True }
            , Http.post
                { url = Url.Builder.relative [ "set-word" ] []
                , body =
                    Http.jsonBody <|
                        Encode.object
                            [ ( "sid", Encode.string model.sid )
                            , ( "pid", Encode.string model.pid )
                            , ( "word", Encode.string model.word )
                            ]
                , expect = Http.expectWhatever SetWord
                }
            )

        ReceivedSid response ->
            case response of
                Ok sid ->
                    ( model
                    , Navigation.load <|
                        Url.Builder.relative [] [ Url.Builder.string "sid" sid ]
                    )

                Err _ ->
                    ( { model | alert = Just "Failed to create session." }, Cmd.none )

        ReceivedPid response ->
            case response of
                Ok pid ->
                    ( { model | pid = pid, screen = LoadingMenu, polling = True }
                    , Cmd.none
                    )

                Err _ ->
                    ( { model | alert = Just "Failed to join session." }, Cmd.none )

        ReceivedState response ->
            case response of
                Ok state ->
                    ( { model
                        | screen =
                            if state.isLobby then
                                LobbyMenu

                            else
                                ActiveGame
                        , stateCache = state
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( { model | alert = Just "Failed to get session state." }, Cmd.none )

        SetWord _ ->
            ( model, Cmd.none )

        ChangeName name ->
            ( { model | name = name }, Cmd.none )

        ChangeWord word ->
            ( { model | word = String.toLower word }, Cmd.none )



-- SUBSCRIPTION


pollInterval : Float
pollInterval =
    1000


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.polling then
        Time.every pollInterval (\_ -> PostGetState)

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
                            [ Events.onClick PostNewSession ]
                            [ Html.text "Create Game" ]
                       ]

            JoinMenu ->
                [ Html.text "Choose name: "
                , Html.input [ Events.onInput ChangeName ] []
                , Html.button
                    [ Events.onClick PostJoinSession ]
                    [ Html.text "Join Game" ]
                ]

            LoadingMenu ->
                [ Html.h2
                    []
                    [ Html.text "Joining game..." ]
                ]

            LobbyMenu ->
                [ Html.h2 []
                    [ Html.text "Game Lobby" ]
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
                        Dict.values model.stateCache.players
                    )
                , Html.p []
                    [ Html.text "Choose word:"
                    , Html.input
                        [ Events.onInput ChangeWord
                        , Attributes.disabled model.ready
                        ]
                        []
                    , Html.button
                        [ Events.onClick PostSetWord
                        , Attributes.disabled model.ready
                        ]
                        [ Html.text "Ready" ]
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

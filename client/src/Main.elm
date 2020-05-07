module Main exposing (..)

import Browser
import Browser.Navigation as Navigation
import Debug
import Dict exposing (Dict)
import Html
import Html.Events as Events
import Html.Attributes as Attributes
import Http
import Json.Encode as Encode
import State exposing (..)
import Time
import Url exposing (Url)
import Url.Builder
import Url.Parser exposing ((<?>), Parser)
import Url.Parser.Query



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
    , route : Maybe Route
    , alert : Maybe String
    , sid : String
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
    | Error

type Route
    = Root (Maybe String)


routeParser : Parser (Route -> a) a
routeParser =
    Url.Parser.oneOf
        [ Url.Parser.map
            Root
            (Url.Parser.top <?> Url.Parser.Query.string "sid")
        ]


init : () -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init _ url _ =
    let
        route =
            Url.Parser.parse routeParser url
    in
    ( { screen =
            case route of
                Just (Root maybeSid) ->
                    case maybeSid of
                        Just sid ->
                            JoinMenu

                        Nothing ->
                            WelcomeMenu

                Nothing ->
                    Error
      , route = route
      , alert = Nothing
      , sid = 
            case route of
                Just (Root maybeSid) ->
                    case maybeSid of 
                        Just sid -> 
                            sid
                    
                        Nothing -> 
                            "<NULL_SID>"
                
                Nothing ->
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



-- -- ONURLCHANGE
--
-- onUrlChange : Url -> (Model, Cmd Msg)
-- onUrlChange url =
--     ( { sid = sid
--       , route = route
--       , alert = Nothing
--       }
--     , Cmd.none
--     )
-- UPDATE


type Msg
    = NoOp
    | PostNewSession
    | PostJoinSession 
    | PostGetState
    | PostSetWord
    | ReceivedSid (Result Http.Error String)
    | ReceivedPid (Result Http.Error String)
    | ReceivedState (Result Http.Error (SessionState))
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
                , body = Http.jsonBody <| 
                    Encode.object
                        [ ("sid", Encode.string model.sid)
                        , ("name", Encode.string model.name)
                        ]
                , expect = Http.expectString ReceivedPid 
                }
            )

        PostGetState ->
            ( model
            , Http.post
                { url = Url.Builder.relative [ "get-state" ] []
                , body = Http.jsonBody <| 
                    Encode.object [ ("sid", Encode.string model.sid) ]
                , expect = Http.expectJson ReceivedState decodeSessionState
                }
            )

        PostSetWord ->
            
            ( { model | ready = True }
            , Http.post
                { url = Url.Builder.relative [ "set-word" ] []
                , body = Http.jsonBody <| 
                    Encode.object 
                    [ ("sid", Encode.string model.sid) 
                    , ("pid", Encode.string model.pid)
                    , ("word", Encode.string model.word)
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
                      | screen = if state.isLobby then LobbyMenu else ActiveGame
                      , stateCache = state
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( { model | alert = Just "Failed to get session state."}, Cmd.none )

        SetWord _ ->
            ( model, Cmd.none )

        ChangeName name ->
            ( { model | name = name }, Cmd.none )

        ChangeWord word ->
            ( { model | word = String.toLower word }, Cmd.none ) 



-- SUBSCRIPTION


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.polling then 
        Time.every 1000 (\_ -> PostGetState)
    else
        Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
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
            { title = "ㅎ Hangmen ㅎ"
            , body =
                maybeErrorMsg
                    ++ [ Html.h1 [] [ Html.text "ㅎ Hangmen ㅎ" ]
                       , Html.button
                            [ Events.onClick PostNewSession ]
                            [ Html.text "Create Session" ]
                       ]
            }
        
        JoinMenu ->
            { title = "ㅎ Hangmen ㅎ"
            , body = 
                [ Html.p [] 
                    [ Html.text "Choose name:" 
                    , Html.input [ Events.onInput ChangeName ] []
                    , Html.button 
                        [ Events.onClick PostJoinSession ]
                        [ Html.text "Join Session" ]
                    ]
                ]
            }

        LoadingMenu ->
            { title = "ㅎ Hangmen ㅎ"
            , body = 
                [ Html.h2 
                    [] 
                    [ Html.text "Joining game..." ]
                ]
            }

        LobbyMenu ->
            { title = "ㅎ Hangmen ㅎ"
            , body = 
                [ Html.h2 []
                    [ Html.text "Game Lobby" ]
                , Html.h3 []
                    [ Html.text "Players:" ]
                , Html.ul [] 
                        ( List.map 
                            ( \player ->
                                Html.li [] 
                                    [ Html.text <| 
                                        player.name 
                                        ++ ": " 
                                        ++ if player.ready then "Ready" 
                                           else "Not Ready" 
                                    ] 
                            )
                            <| Dict.values model.stateCache.players
                        )
                , Html.p []
                    [ Html.text "Choose word:"
                    , Html.input 
                        [ Events.onInput ChangeWord 
                        , Attributes.disabled model.ready ] 
                        []
                    , Html.button 
                        [ Events.onClick PostSetWord
                        , Attributes.disabled model.ready ]
                        [ Html.text "Ready" ]
                    ]
                ]
            }

        ActiveGame ->
            { title = "ㅎ Hangmen ㅎ"
            , body =
                [ Html.h1 [] [ Html.text "ㅎ Hangmen ㅎ" ]
                , Html.h2 [] [ Html.text "Active game screen" ]
                ]
            }

        Error ->
            { title = "ㅎ Hangmen ㅎ"
            , body =
                [ Html.h1 [] [ Html.text "404" ]
                ]
            }

renderSession : String -> SessionState -> Browser.Document Msg
renderSession name state =
    { title = "ㅎ Hangmen ㅎ"
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


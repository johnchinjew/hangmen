module Main exposing (..)

import Browser
import Browser.Navigation as Navigation
import Dict exposing (Dict)
import Html
import Html.Events as Events
import Http
import Json.Encode as Encode
import Json.Decode as Decode
import String
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
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { screen : Screen
    , route : Maybe Route
    , alert : Maybe String
    , sid : String
    , pid : String
    , name : String
    , state : List String
    }


type Screen
    = WelcomeMenu
    | JoiningSession 
    | RenderSession
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
                            JoiningSession

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
      , pid = "<NULL_PID>"
      , name = ""
      , state = []
    --     { sid = ""
    --     , players = Dict.fromList []
    --     , turnOrder = []
    --     , alphabet = Dict.fromList []
    --     , isLobby = True
    --     }
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
    | PostJoinSession String
    | PostGetSession
    | ReceivedSid (Result Http.Error String)
    | ReceivedPid (Result Http.Error String)
    | ReceivedState (Result Http.Error (List String))
    | ChangeName String


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

        PostJoinSession name ->
            ( { model | screen = RenderSession}
            , Http.post
                { url = Url.Builder.relative [ "join-session" ] []
                , body = Http.jsonBody <| 
                    Encode.object
                        [ ("sid", Encode.string model.sid)
                        , ("name", Encode.string name)
                        ]
                , expect = Http.expectString ReceivedPid 
                }
            )

        PostGetSession ->
            ( model
            , Http.post
                { url = Url.Builder.relative [ "join-session" ] []
                , body = Http.jsonBody <| 
                    Encode.object [ ("sid", Encode.string model.sid) ]
                , expect = Http.expectJson ReceivedState (Decode.list Decode.string)
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
                    ( { model | pid = pid, screen = RenderSession }
                    , Http.post
                        { url = Url.Builder.relative [ "get-state" ] []
                        , body = Http.jsonBody <| 
                            Encode.object [ ("sid", Encode.string model.sid) ] 
                        , expect = Http.expectJson ReceivedState (Decode.list Decode.string)
                        }
                    )

                Err _ ->
                    ( { model | alert = Just "Failed to join session." }, Cmd.none )

        ReceivedState response ->
            case response of 
                Ok state -> ( { model | screen = RenderSession, state = state }, Cmd.none)

                Err _ ->
                    ( { model | alert = Just "Failed to get session state."}, Cmd.none )

        ChangeName name ->
           ( { model | name = name }, Cmd.none )





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
        
        JoiningSession ->
            { title = "ㅎ Hangmen ㅎ"
            , body = 
                [ Html.p [] 
                    [ Html.text "Choose name:" 
                    , Html.input [Events.onInput ChangeName] []
                    , Html.button 
                        [ Events.onClick <| PostJoinSession model.name]
                        [ Html.text "Join Session" ]
                    ]
                ]
            }

        RenderSession ->
            let 
                state = String.join "" model.state
            in
            { title = "ㅎ Hangmen ㅎ"
            , body = 
                [ Html.p [] 
                    [ Html.text <| 
                        "sid: " 
                            ++ model.sid
                            ++ " | pid: "
                            ++ model.pid
                            ++ " | name: "
                            ++ model.name
                            ++ " | state: " 
                            ++ state
                    ]

                ]
            }

        Error ->
            { title = "ㅎ Hangmen ㅎ"
            , body =
                [ Html.h1 [] [ Html.text "404" ]
                ]
            }

type alias PlayerState = 
    { pid : String
    , name : String
    , word : String
    , ready : Bool
    , alive : Bool
    }

type alias SessionState = 
    { sid : String
    , players : Dict String PlayerState
    , turnOrder : List Int
    , alphabet : Dict Char Bool
    , isLobby : Bool
    }

-- playerStateDecoder : Decode.Decoder PlayerState
-- playerStateDecoder = 
--     Decode.map5 PlayerState
--         (Decode.field "id" Decode.string)
--         (Decode.field "name" Decode.string)
--         (Decode.field "word" Decode.string)
--         (Decode.field "ready" Decode.bool)
--         (Decode.field "alive" Decode.bool)

-- sessionStateDecoder : Decode.Decoder SessionState
-- sessionStateDecoder = 
--     Decode.map5 SessionState
--         (Decode.field "id" Decode.string)
--         (Decode.field "players" Decode.dict Decode.string playerStateDecoder)
--         (Decode.field "turnOrder" Decode.list Decode.int)
--         (Decode.field "alphabet" Decode.dict )



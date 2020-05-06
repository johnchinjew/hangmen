module Main exposing (..)

import Browser
import Browser.Navigation as Navigation
import Html exposing (Html)
import Html.Events as Events
import Http
import Json.Encode as Encode
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
    }


type Screen
    = WelcomeMenu
    | ExistingSession String
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
                            ExistingSession sid

                        Nothing ->
                            WelcomeMenu

                Nothing ->
                    Error
      , route = route
      , alert = Nothing
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
    | ReceivedSid (Result Http.Error String)


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

        ReceivedSid response ->
            case response of
                Ok sid ->
                    ( model
                    , Navigation.load <|
                        Url.Builder.relative [] [ Url.Builder.string "sid" sid ]
                    )

                Err _ ->
                    ( { model | alert = Just "Failed to create session." }, Cmd.none )



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
                            [ Html.text "Create Game" ]
                       ]
            }

        ExistingSession sid ->
            { title = "ㅎ Hangmen ㅎ"
            , body =
                [ Html.p []
                    [ Html.text <|
                        "Route: Existing Session with sid: "
                            ++ sid
                    ]
                ]
            }

        Error ->
            { title = "ㅎ Hangmen ㅎ"
            , body =
                [ Html.h1 [] [ Html.text "404" ]
                ]
            }

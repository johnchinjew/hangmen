module Main exposing (..)

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
    | Game Session


type alias LobbyData =
    { session : Session
    , word : String
    , connectivityIssues : Bool
    }


type alias HomeData =
    { start : Start
    , pin : String
    , name : String
    , error : Bool
    }


type Start
    = Create
    | Join


init : () -> ( Model, Cmd Msg )
init _ =
    ( Home <| HomeData Create "" "" False
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
      -- LOBBY
    | ChangedWord String
    | ClickedStartGame
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

        ( OnGameUpdate game, Home h ) ->
            ( Lobby (LobbyData game "" False) |> Debug.log "received game!"
            , Cmd.none
            )

        -- LOBBY
        ( ChangedWord word, Lobby l ) ->
            ( Lobby { l | word = word }, Cmd.none )

        ( ClickedStartGame, Lobby l ) ->
            ( model, Socket.emitStartGame l.word )

        ( OnGameUpdate game, Lobby l ) ->
            ( Lobby { l | session = game } |> Debug.log "received game!"
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
    Ports.fromSocket
        (\value ->
            case Decode.decodeValue Session.decode value of
                Ok session ->
                    OnGameUpdate session

                Err _ ->
                    NoOp |> Debug.log "uh oh"
        )



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
                    ++ [ Html.h2 []
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

            _ ->
                [ Html.text "not implemented" ]
    }

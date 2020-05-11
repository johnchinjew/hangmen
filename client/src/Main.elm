module Main exposing (..)

import Browser
import Debug
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import Pin exposing (Pin)
import Regex exposing (Regex)



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type Model
    = Home HomeData
    | Game


type alias HomeData =
    { start : Start
    , pin : String
    , name : String
    , word : String
    , error : Bool
    }


type Start
    = Create
    | Join


init : () -> ( Model, Cmd Msg )
init _ =
    ( Home <| HomeData Create "" "" "" False
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
      -- HOME
    | PickStart Start
    | ChangedPin String
    | ChangedName String
    | ChangedWord String
    | ClickedStart


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

        ( ChangedWord word, Home h ) ->
            ( Home { h | word = word, error = False }, Cmd.none )

        ( ClickedStart, Home h ) ->
            ( Home { h | error = not <| valid h }
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

        wordLength =
            2 <= String.length h.word && String.length h.word <= 30

        alphabeticWord =
            alphabetic h.word

        validPin =
            h.start == Create || Pin.fromString h.pin /= Nothing
    in
    nameLength && wordLength && alphabeticWord && validPin


letters : Regex
letters =
    Maybe.withDefault Regex.never <| Regex.fromString "^[a-zA-Z]+$"


alphabetic : String -> Bool
alphabetic string =
    (String.length <| Regex.replaceAtMost 1 letters (\match -> "") string) == 0



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
                       , Html.p []
                            [ Html.text "Word: "
                            , Html.input
                                [ Attributes.placeholder "Choose word"
                                , Attributes.value h.word
                                , Events.onInput ChangedWord
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
                       , Html.p [] [ Html.text "Created by Eero Gallano and John Chin-Jew." ]
                       ]

            _ ->
                [ Html.text "not implemented" ]
    }

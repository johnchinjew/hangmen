module Main exposing (..)

import Browser
import Debug
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events



-- MAIN


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


type alias HomeData =
    { name : Maybe String, word : Maybe String, begin : Begin, pin : Maybe String }


type Begin
    = Create
    | Join


init : () -> ( Model, Cmd Msg )
init _ =
    ( Home { name = Nothing, word = Nothing, begin = Create, pin = Nothing }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
      -- HOME
    | PickedBegin Begin
    | ChangedPin String
    | ChangedName String
    | ChangedWord String
    | ClickedGo


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( NoOp, _ ) ->
            ( model, Cmd.none )

        -- HOME
        ( PickedBegin begin, Home h ) ->
            ( Home { h | begin = begin }, Cmd.none )

        ( ChangedPin pin, Home h ) ->
            ( Home { h | pin = Just pin }, Cmd.none )

        ( ChangedName name, Home h ) ->
            ( Home { h | name = Just name }, Cmd.none )

        ( ChangedWord word, Home h ) ->
            ( Home { h | word = Just word }, Cmd.none )

        ( ClickedGo, Home _ ) ->
            ( model
            , Cmd.none
            )



-- CATCHALL
-- ( _, _ ) ->
--     update NoOp model
-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "Hangmen"
    , body =
        case model of
            Home h ->
                [ Html.h1 [] [ Html.text "Hangmen" ]
                , Html.p []
                    [ Html.text "Scalable hangman." ]
                , radio
                    [ Html.text "Create game" ]
                    "begin"
                    (h.begin == Create)
                    (PickedBegin Create)
                , radio
                    [ Html.text "Join existing game"
                    , Html.input [ Attributes.placeholder "Enter game PIN" ] []
                    ]
                    "begin"
                    (h.begin == Join)
                    (PickedBegin Join)
                , Html.br [] []
                , Html.input
                    [ Attributes.placeholder "Enter name"
                    , Events.onInput ChangedName
                    ]
                    []
                , Html.br [] []
                , Html.input
                    [ Attributes.placeholder "Choose word"
                    , Events.onInput ChangedWord
                    ]
                    []
                , Html.br [] []
                , Html.button [ Events.onClick ClickedGo ] [ Html.text "Go" ]
                ]
    }


radio : List (Html msg) -> String -> Bool -> msg -> Html msg
radio label group checked changed =
    Html.div []
        ((Html.input
            [ Attributes.type_ "radio"
            , Attributes.name group
            , Attributes.checked checked
            , Events.onClick changed
            ]
            [])
            :: label
        )

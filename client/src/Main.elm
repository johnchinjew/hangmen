module Main exposing (..)

import Browser
import Html exposing (Html)
import Html.Events
import Http
import Set exposing (Set)


alphabet =
    "abcdefghijklmnopqrstuvwxyz"



-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { words : List String
    , selected : Set Char
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model [ "hello", "world" ] (Set.fromList (String.toList "abcdefghijkl")), Cmd.none )



-- UPDATE


type Msg
    = NoOp
    | HttpNoOp (Result Http.Error ())
    | Post


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        HttpNoOp _ ->
            update NoOp model

        Post ->
            ( model, blankPost )



-- VIEW


view : Model -> Html Msg
view model =
    Html.div []
        [ Html.ul [] (viewWords model)
        , Html.button [ Html.Events.onClick Post ] [ Html.text "POST" ]
        ]


viewWords : Model -> List (Html Msg)
viewWords model =
    List.map
        (\word ->
            Html.li
                []
                [ Html.text (unfinishedWord model.selected word) ]
        )
        model.words


unfinishedWord : Set Char -> String -> String
unfinishedWord selectedLetters word =
    String.map
        (\letter ->
            if Set.member letter selectedLetters then
                letter

            else
                '-'
        )
        word


blankPost : Cmd Msg
blankPost =
    Http.post
        { url = "http://localhost:3000/get-new-session"
        , body = Http.stringBody "application/json" "sup"
        , expect = Http.expectWhatever HttpNoOp
        }

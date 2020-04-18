module Main exposing (..)

import Browser
import Html exposing (Html)
import Html.Events as Events
import Http
import Json.Encode as Encode



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
    ()


init : () -> ( Model, Cmd Msg )
init _ =
    ( (), Cmd.none )



-- UPDATE


type Msg
    = DiscardString String
    | ReceivedString (Result Http.Error String)
    | PostNewSession
    | PostJoinSession
    | PostResetSession
    | PostGetState
    | PostSetWord
    | PostGuessLetter
    | PostGuessWord


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DiscardString _ ->
            ( model, Cmd.none )

        ReceivedString response ->
            case response of
                Ok string ->
                    update (DiscardString (Debug.log "Received" string)) model

                Err err ->
                    ( model, Cmd.none )

        PostNewSession ->
            ( model
            , Http.post
                { url = "http://localhost:3000/new-session"
                , body = Http.emptyBody
                , expect = Http.expectString ReceivedString
                }
            )

        PostResetSession ->
            ( model
            , Http.post
                { url = "http://localhost:3000/reset-session"
                , body = Http.emptyBody
                , expect = Http.expectString ReceivedString
                }
            )

        PostJoinSession ->
            let
                body : Encode.Value
                body =
                    Encode.object
                        [ ( "sid", Encode.string "be6a285d-6342-4964-b190-13c5a3d1fd44" )
                        , ( "name", Encode.string "Phineas" )
                        ]
            in
            ( model
            , Http.post
                { url = "http://localhost:3000/join-session"
                , body = Http.jsonBody body
                , expect = Http.expectString ReceivedString
                }
            )

        PostGetState ->
            let
                body : Encode.Value
                body =
                    Encode.object
                        [ ( "sid", Encode.string "be6a285d-6342-4964-b190-13c5a3d1fd44" )
                        ]
            in
            ( model
            , Http.post
                { url = "http://localhost:3000/get-state"
                , body = Http.jsonBody body
                , expect = Http.expectString ReceivedString
                }
            )

        PostSetWord ->
            ( model
            , Http.post
                { url = "http://localhost:3000/set-word"
                , body = Http.emptyBody
                , expect = Http.expectString ReceivedString
                }
            )

        PostGuessLetter ->
            ( model
            , Http.post
                { url = "http://localhost:3000/guess-letter"
                , body = Http.emptyBody
                , expect = Http.expectString ReceivedString
                }
            )

        PostGuessWord ->
            ( model
            , Http.post
                { url = "http://localhost:3000/guess-word"
                , body = Http.emptyBody
                , expect = Http.expectString ReceivedString
                }
            )



-- VIEW


view : Model -> Html Msg
view model =
    Html.ul []
        [ Html.li [] [ Html.button [ Events.onClick PostNewSession ] [ Html.text "POST: new-session" ] ]
        , Html.li [] [ Html.button [ Events.onClick PostResetSession ] [ Html.text "POST: reset-session" ] ]
        , Html.li [] [ Html.button [ Events.onClick PostJoinSession ] [ Html.text "POST: join-session" ] ]
        , Html.li [] [ Html.button [ Events.onClick PostGetState ] [ Html.text "POST: get-state" ] ]
        , Html.li [] [ Html.button [ Events.onClick PostSetWord ] [ Html.text "POST: set-word" ] ]
        , Html.li [] [ Html.button [ Events.onClick PostGuessLetter ] [ Html.text "POST: guess-letter" ] ]
        , Html.li [] [ Html.button [ Events.onClick PostGuessWord ] [ Html.text "POST: guess-word" ] ]
        ]

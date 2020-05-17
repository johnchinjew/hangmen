module Session exposing (..)

import Alphabet exposing (Alphabet)
import Dict exposing (Dict)
import Json.Decode as Decode
import Player exposing (Player)


type alias Session =
    { pin : String
    , players : Dict String Player
    , turnOrder : List String
    , alphabet : Alphabet
    , isLobby : Bool
    }


type Status
    = Winner String
    | Draw
    | Playing



-- QUERY


turn : Session -> Maybe String
turn session =
    List.head session.turnOrder


status : Session -> Status
status session =
    let
        gameover =
            List.length session.turnOrder <= 1
    in
    if gameover then
        case List.head session.turnOrder of
            Just playerPin ->
                Winner playerPin

            Nothing ->
                Draw

    else
        Playing


playerName : String -> Session -> String
playerName pid session =
    case Dict.get pid session.players of
        Just player ->
            player.name

        Nothing ->
            "Unknown"



-- DECODERS


decode : Decode.Decoder Session
decode =
    Decode.map5 Session
        (Decode.field "pin" Decode.string)
        (Decode.field "players" <| Decode.dict Player.decode)
        (Decode.field "turnOrder" <| Decode.list Decode.string)
        (Decode.field "alphabet" Alphabet.decode)
        (Decode.field "isLobby" Decode.bool)

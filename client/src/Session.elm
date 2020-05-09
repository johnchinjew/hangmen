module Session exposing (..)

import Alphabet exposing (Alphabet)
import Dict exposing (Dict)
import Json.Decode as Decode
import Player exposing (Player)


type alias Session =
    { sid : String
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
            Just pid ->
                Winner pid

            Nothing ->
                Draw

    else
        Playing



-- DECODERS


decode : Decode.Decoder Session
decode =
    Decode.map5 Session
        (Decode.field "id" Decode.string)
        (Decode.field "players" <| Decode.dict Player.decode)
        (Decode.field "turnOrder" <| Decode.list Decode.string)
        (Decode.field "alphabet" Alphabet.decode)
        (Decode.field "isLobby" Decode.bool)

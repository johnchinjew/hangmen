module Player exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode


type alias Player =
    { pin : String
    , name : String
    , word : String
    , ready : Bool
    , alive : Bool
    }



-- DECODERS


decode : Decode.Decoder Player
decode =
    Decode.map5 Player
        (Decode.field "pin" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "word" Decode.string)
        (Decode.field "ready" Decode.bool)
        (Decode.field "alive" Decode.bool)

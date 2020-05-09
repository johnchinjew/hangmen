module Alphabet exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode


type alias Alphabet =
    { letters : Dict String Bool }



-- DECODER


decode : Decode.Decoder Alphabet
decode =
    Decode.map Alphabet
        (Decode.field "letters" <| Decode.dict Decode.bool)

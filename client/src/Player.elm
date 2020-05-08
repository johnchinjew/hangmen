module Player exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode


type alias Player =
    { id : String
    , name : String
    , word : String
    , ready : Bool
    , alive : Bool
    }



-- DECODERS


decode : Decode.Decoder Player
decode =
    Decode.map5 Player
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "word" Decode.string)
        (Decode.field "ready" Decode.bool)
        (Decode.field "alive" Decode.bool)



-- DEBUGGING


toString : Player -> String
toString player =
    "{ id: "
        ++ player.id
        ++ " name: "
        ++ player.name
        ++ " word: "
        ++ player.word
        ++ " ready: "
        ++ (if player.ready then
                "True"

            else
                "False"
                    ++ " alive: "
                    ++ (if player.alive then
                            "True }"

                        else
                            "False }"
                       )
           )

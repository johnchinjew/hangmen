module Socket exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode
import Ports



-- OUTBOUND


openAndEmitCreateGame : String -> String -> Cmd msg
openAndEmitCreateGame name word =
    Ports.toSocket
        (Encode.object
            [ ( "event", Encode.string "create-game" )
            , ( "name", Encode.string name )
            , ( "word", Encode.string word )
            ]
        )



-- INBOUND

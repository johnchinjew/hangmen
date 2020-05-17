module Socket exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode
import Ports
import Session exposing (Session)



-- OUTBOUND


emitCreateGame : String -> Cmd msg
emitCreateGame name =
    Ports.toSocket
        (Encode.object
            [ ( "tag", Encode.string "create-game" )
            , ( "name", Encode.string name )
            ]
        )


emitJoinGame : String -> String -> Cmd msg
emitJoinGame pin name =
    Ports.toSocket
        (Encode.object
            [ ( "tag", Encode.string "join-game" )
            , ( "pin", Encode.string pin )
            , ( "name", Encode.string name )
            ]
        )


emitStartGame : String -> Cmd msg
emitStartGame word =
    Ports.toSocket
        (Encode.object
            [ ( "tag", Encode.string "start-game" )
            , ( "word", Encode.string word )
            ]
        )



-- INBOUND
-- onGameUpdate : (Decode.Value -> msg) -> Sub msg
-- onGameUpdate msg =
--     Ports.fromSocket (Decode.decodeValue (Decode.map msg Session.decode))
-- (Decode.Value -> msg) -> Sub msg
-- Ports.fromSocket (Decode.map msg Decode.string)

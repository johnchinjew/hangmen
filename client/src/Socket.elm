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


emitSetWord : String -> Cmd msg
emitSetWord word =
    Ports.toSocket
        (Encode.object
            [ ( "tag", Encode.string "set-word" )
            , ( "word", Encode.string word )
            ]
        )


emitStartGame : Cmd msg 
emitStartGame = 
    Ports.toSocket
        (Encode.object
            [ ( "tag", Encode.string "start-game" )
            ]
        )

-- emitStartGame : String -> Cmd msg
-- emitStartGame word =
--     Ports.toSocket
--         (Encode.object
--             [ ( "tag", Encode.string "start-game" )
--             , ( "word", Encode.string word )
--             ]
--         )


emitGuessLetter : String -> Cmd msg
emitGuessLetter letter =
    Ports.toSocket
        (Encode.object
            [ ( "tag", Encode.string "guess-letter" )
            , ( "letter", Encode.string letter )
            ]
        )


emitGuessWord : String -> String -> Cmd msg
emitGuessWord pin word =
    Ports.toSocket
        (Encode.object
            [ ( "tag", Encode.string "guess-word" )
            , ( "pin", Encode.string pin )
            , ( "word", Encode.string word )
            ]
        )



-- INBOUND
-- onGameUpdate : (Decode.Value -> msg) -> Sub msg
-- onGameUpdate msg =
--     Ports.fromSocket (Decode.decodeValue (Decode.map msg Session.decode))
-- (Decode.Value -> msg) -> Sub msg
-- Ports.fromSocket (Decode.map msg Decode.string)

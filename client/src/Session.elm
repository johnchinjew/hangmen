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



-- DECODERS


decode : Decode.Decoder Session
decode =
    Decode.map5 Session
        (Decode.field "id" Decode.string)
        (Decode.field "players" <| Decode.dict Player.decode)
        (Decode.field "turnOrder" <| Decode.list Decode.string)
        (Decode.field "alphabet" Alphabet.decode)
        (Decode.field "isLobby" Decode.bool)



-- DEBUGGING


toString : Session -> String
toString session =
    "{ sid: "
        ++ session.sid
        ++ " players: ["
        ++ String.join
            ""
            (List.map
                (\player -> Player.toString player)
                (Dict.values session.players)
            )
        ++ "] turn order: [ "
        ++ String.join
            ""
            (List.map
                (\pid -> pid ++ ", ")
                session.turnOrder
            )
        ++ " ]"
        ++ " alphabet: "
        ++ Alphabet.toString session.alphabet
        ++ " lobby: "
        ++ (if session.isLobby then
                "True"

            else
                "False"
                    ++ " }"
           )

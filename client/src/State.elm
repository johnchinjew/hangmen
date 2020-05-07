module State exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode


type alias AlphabetState =
    { letters : Dict String Bool }


type alias PlayerState =
    { pid : String
    , name : String
    , word : String
    , ready : Bool
    , alive : Bool
    }


type alias SessionState =
    { sid : String
    , players : Dict String PlayerState
    , turnOrder : List String
    , alphabet : AlphabetState
    , isLobby : Bool
    }



-- DECODERS


decodeAlphabetState : Decode.Decoder AlphabetState
decodeAlphabetState =
    Decode.map AlphabetState
        (Decode.field "letters" <| Decode.dict Decode.bool)


decodePlayerState : Decode.Decoder PlayerState
decodePlayerState =
    Decode.map5 PlayerState
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "word" Decode.string)
        (Decode.field "ready" Decode.bool)
        (Decode.field "alive" Decode.bool)


decodeSessionState : Decode.Decoder SessionState
decodeSessionState =
    Decode.map5 SessionState
        (Decode.field "id" Decode.string)
        (Decode.field "players" <| Decode.dict decodePlayerState)
        (Decode.field "turnOrder" <| Decode.list Decode.string)
        (Decode.field "alphabet" decodeAlphabetState)
        (Decode.field "isLobby" Decode.bool)



-- TO STRING (FOR DEBUGGING)


alphabetStateToString : AlphabetState -> String
alphabetStateToString alphabet =
    "{ "
        ++ String.join ""
            (List.map
                (\pair ->
                    " "
                        ++ Tuple.first pair
                        ++ " : "
                        ++ (if Tuple.second pair then
                                "True"

                            else
                                "False"
                           )
                )
                (Dict.toList alphabet.letters)
            )
        ++ " } "


playerStateToString : PlayerState -> String
playerStateToString player =
    "{ pid: "
        ++ player.pid
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


sessionStateToString : SessionState -> String
sessionStateToString session =
    "{ sid: "
        ++ session.sid
        ++ " players: ["
        ++ String.join
            ""
            (List.map
                (\player -> playerStateToString player)
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
        ++ alphabetStateToString session.alphabet
        ++ " lobby: "
        ++ (if session.isLobby then
                "True"

            else
                "False"
                    ++ " }"
           )

module Session exposing (..)

import Alphabet exposing (Alphabet)
import Dict exposing (Dict)
import Json.Decode as Decode
import Time
import Player exposing (Player)


type alias Session =
    { pin : String
    , players : Dict String Player
    , turnOrder : List String
    , endtime : Int
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


timeLeft : Time.Posix -> Session -> Int 
timeLeft now session = 
    ( session.endtime - Time.posixToMillis now ) // 1000


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


playerWord : String -> Session -> String
playerWord pid session =
    case Dict.get pid session.players of
        Just player ->
            player.word 

        Nothing ->
            "Unknown"


playerReady : String -> Session -> Bool
playerReady pid session = 
    case Dict.get pid session.players of
        Just player ->
            player.ready

        Nothing ->
            False

playerAlive : String -> Session -> Bool
playerAlive pid session =
    case Dict.get pid session.players of 
        Just player ->
            player.alive 

        Nothing -> 
            False


-- DECODERS


decode : Decode.Decoder Session
decode =
    Decode.map6 Session
        (Decode.field "pin" Decode.string)
        (Decode.field "players" <| Decode.dict Player.decode)
        (Decode.field "turnOrder" <| Decode.list Decode.string)
        (Decode.field "endtime" <| Decode.int)
        (Decode.field "alphabet" Alphabet.decode)
        (Decode.field "isLobby" Decode.bool)

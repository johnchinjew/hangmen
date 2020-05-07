module Api exposing (..)

import Http
import Json.Encode as Encode
import State exposing (SessionState)
import Url.Builder


postNewSession : (Result Http.Error String -> msg) -> Cmd msg
postNewSession responseHandler =
    Http.post
        { url = Url.Builder.relative [ "new-session" ] []
        , body = Http.emptyBody
        , expect = Http.expectString responseHandler
        }


postJoinSession : { sid : String, name : String } -> (Result Http.Error String -> msg) -> Cmd msg
postJoinSession { sid, name } responseHandler =
    Http.post
        { url = Url.Builder.relative [ "join-session" ] []
        , body =
            Http.jsonBody <|
                Encode.object
                    [ ( "sid", Encode.string sid )
                    , ( "name", Encode.string name )
                    ]
        , expect = Http.expectString responseHandler
        }


postGetState : { sid : String } -> (Result Http.Error SessionState -> msg) -> Cmd msg
postGetState { sid } responseHandler =
    Http.post
        { url = Url.Builder.relative [ "get-state" ] []
        , body =
            Http.jsonBody <|
                Encode.object [ ( "sid", Encode.string sid ) ]
        , expect = Http.expectJson responseHandler State.decodeSessionState
        }


postSetWord : { sid : String, pid : String, word : String } -> (Result Http.Error () -> msg) -> Cmd msg
postSetWord { sid, pid, word } responseHandler =
    Http.post
        { url = Url.Builder.relative [ "set-word" ] []
        , body =
            Http.jsonBody <|
                Encode.object
                    [ ( "sid", Encode.string sid )
                    , ( "pid", Encode.string pid )
                    , ( "word", Encode.string word )
                    ]
        , expect = Http.expectWhatever responseHandler
        }

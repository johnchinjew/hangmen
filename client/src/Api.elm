module Api exposing (..)

import Http
import Json.Encode as Encode
import Session exposing (Session)
import Url.Builder



-- Each of these functions represents a backend API endpoint.
-- They will return a Cmd that is used to tell Elm to make an HTTP request on your behalf.
-- For each function, you must supply the responseHandler which takes in
-- the response received from the backend (packaged as a Result type) as an argument
-- and returns a msg type for you to use in your update function.
-- For some endpoints, arguments are required to create a meaningful request.


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


postGetState : { sid : String } -> (Result Http.Error Session -> msg) -> Cmd msg
postGetState { sid } responseHandler =
    Http.post
        { url = Url.Builder.relative [ "get-state" ] []
        , body =
            Http.jsonBody <|
                Encode.object [ ( "sid", Encode.string sid ) ]
        , expect = Http.expectJson responseHandler Session.decode
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

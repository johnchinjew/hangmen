module Route exposing (..)

import Url exposing (Url)
import Url.Parser exposing ((<?>), Parser)
import Url.Parser.Query


type alias SessionId =
    String


type Route
    = Invalid
    | Root (Maybe SessionId)


parser : Parser (Route -> a) a
parser =
    Url.Parser.oneOf
        [ Url.Parser.map Root (Url.Parser.top <?> Url.Parser.Query.string "sid")
        ]


parse : Url -> Route
parse url =
    case Url.Parser.parse parser url of
        Just route ->
            route

        Nothing ->
            Invalid

module Route exposing (..)

import Url exposing (Url)
import Url.Builder
import Url.Parser exposing ((<?>), Parser)
import Url.Parser.Query


type Route
    = Invalid
    | Root (Maybe String)


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



-- LOCATIONS


withQuerySid : String -> String
withQuerySid sid =
    Url.Builder.absolute [] [ Url.Builder.string "sid" sid ]


shareLink : String -> String
shareLink sid =
    "https://hangm.en" ++ withQuerySid sid

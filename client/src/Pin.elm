module Pin exposing (Pin, fromString, toString)

import Regex exposing (Regex)


type Pin
    = Pin String


pattern : Regex
pattern =
    Maybe.withDefault Regex.never <| Regex.fromString "^[a-z0-9]{6}$"


valid : String -> Bool
valid pin =
    (String.length <| Regex.replaceAtMost 1 pattern (\match -> "") pin) == 0


fromString : String -> Maybe Pin
fromString pin =
    if valid pin then
        Just <| Pin pin

    else
        Nothing


toString : Pin -> String
toString (Pin pin) =
    pin

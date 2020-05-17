port module Ports exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode


port toSocket : Encode.Value -> Cmd msg


port fromSocket : (Decode.Value -> msg) -> Sub msg

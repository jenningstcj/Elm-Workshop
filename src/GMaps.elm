port module GMaps exposing (..)

import SharedModels exposing (GMPos)


-- OUTGOING PORTS

port moveMap : GMPos -> Cmd msg

-- INCOMING PORTS

port mapMoved : (GMPos -> msg) -> Sub msg

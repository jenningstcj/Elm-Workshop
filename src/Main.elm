module Main exposing (..)

import Html exposing (Html, div, p, text)
import SharedModels exposing (GMPos)
import GMaps exposing (moveMap, mapMoved)


-- MAIN


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
        


type alias Model =
    { pos : GMPos
    , alt : Int
    , vel : Int
    }



-- INIT


init : ( Model, Cmd Msg )
init =
    let
        knoxville =
            (GMPos 35.9335673 -84.016913)
    in
        ( Model knoxville 0 0, moveMap knoxville )



-- UPDATE


type Msg
    = MapMovedUpdate GMPos


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MapMovedUpdate newPos ->
            ( { model | pos = newPos }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ h3 [] [text "Tracking the International Space Station"]
        , p [] [ text ("Latitude: " ++ toString model.pos.lat) ]
        , p [] [ text ("Longitude: " ++ toString model.pos.lng) ]
        , p [] [ text ("Altitude: " ++ toString model.alt ++ " miles") ]
        , p [] [ text ("Velocity: " ++ toString model.vel ++ " miles per hour") ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [
          mapMoved MapMovedUpdate
        ]

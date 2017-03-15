module Main exposing (..)

import Html exposing (Html, div, p, text)
import SharedModels exposing (GMPos)
import GMaps exposing (moveMap, mapMoved)
import Http
import Json.Decode exposing (..)
import Time exposing (..)


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


type alias ISS_JSON =
    { latitude : Float
    , longitude : Float
    , altitude : Float
    , velocity : Float
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
    | LoadData (Result Http.Error ISS_JSON)
    | FetchPosition Time


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MapMovedUpdate newPos ->
            ( { model | pos = newPos }, Cmd.none )

        LoadData (Ok newISSPos) ->
             let
                 newPos =
                     GMPos newISSPos.latitude newISSPos.longitude

                 velocity =
                     kilometersToMiles newISSPos.velocity

                 altitude =
                     kilometersToMiles newISSPos.altitude
             in
                 ( { model
                     | pos = newPos
                     , vel = velocity
                     , alt = altitude
                   }
                 , moveMap newPos
                 )

        LoadData (Err _) ->
             ( model, Cmd.none )

        FetchPosition time ->
            ( model, getLocation )

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
        [ mapMoved MapMovedUpdate
        , Time.every (5 * second) FetchPosition
        ]




-- Http


getLocation : Cmd Msg
getLocation =
    let
        url =
            "https://api.wheretheiss.at/v1/satellites/25544"

        request =
            Http.get url decodeISSPosition
    in
       Http.send LoadData request


decodeISSPosition : Decoder ISS_JSON
decodeISSPosition =
    map4 ISS_JSON
        (field "latitude" float)
        (field "longitude" float)
        (field "altitude" float)
        (field "velocity" float)


kilometersToMiles : Float -> Int
kilometersToMiles km =
    km
        * 0.62137
        |> round

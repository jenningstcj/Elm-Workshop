## Elm Workshop

In this short tutorial we will walk through the steps to build the demo from [IntroToElm](https://jenningstcj.github.io/IntroToElm/Demos/GoogleMaps/index.html) where we cover many of the topics that exist in real world applications: Commands, Subscriptions, Http calls, JSON decoding, interop with JavaScript through Ports.  

Go ahead and download branch [01_Start](https://github.com/jenningstcj/Elm-Workshop/tree/01_Start) and follow along with the tutorial below.


Go ahead and install Elm and dependenices for Html and Http with the commands:

```
elm-package install elm-lang/core -y 
```

and

```
elm-package install evancz/elm-http -y
```

This created an elm-package.json file and downloaded the dependencies to the elm-stuff directory.

Go ahead and update the elm-package.json line for source-directories to match the following:

```
"source-directories": [
  "src"
],
```

Then make src/Main.elm for your Elm application and set it up with the basic Elm Architecture for Html.App.Program:

```
module Main exposing (..)

import Html exposing (Html, div, p, text)
import Html.App


-- MAIN


main : Program Never
main =
    Html.App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    {}



-- INIT


init : ( Model, Cmd Msg )
init =
    ( Model, Cmd.none )



-- UPDATE


type Msg
    = Placeholder


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div [] []



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
```


After this, you should match branch [02](https://github.com/jenningstcj/Elm-Workshop/tree/02) and have an application that compiles successfully.  You can compile the application from the root directory with:

```
elm-make --warn src/Main.elm --output=main.js
```

Next we will build our Model.  Since part of our model will be used with Ports, we will create that type alias in a separate file.  Go ahead and make a src/SharedModels.elm file.  We will share a type alias that contains a latitude and longitude to share with our Ports to also use in JavaScript with Google Maps.  In the src/SharedModels.elm file, declare the module and add the following type alias:

```
module SharedModels exposing (..)

type alias GMPos =
  { lat : Float
  , lng : Float
  }
```
Then in the Main.elm file, import the previously created type alias:

```
import SharedModels exposing (GMPos)
```

And fill our our Model type alias with position, altitude, and velocity fields:

```
type alias Model =
    { pos : GMPos
    , alt : Int
    , vel : Int
    }
```

Then update the init function to initialize the new model.  Optionally, we can initialize the position to a specific location like Knoxville:

```
init : ( Model, Cmd Msg )
init =
    let
        knoxville =
            (GMPos 35.9335673 -84.016913)
    in
        ( Model knoxville 0 0, Cmd.none )
```

Let's update our view to be able to see the values of our model:

```

view : Model -> Html Msg
view model =
    div []
        [ p [] [ text ("Latitude: " ++ toString model.pos.lat) ]
        , p [] [ text ("Longitude: " ++ toString model.pos.lng) ]
        , p [] [ text ("Altitude: " ++ toString model.alt ++ " miles") ]
        , p [] [ text ("Velocity: " ++ toString model.vel ++ " miles per hour") ]
        ]
```

Last step in this branch will be to setup Ports to communicate with JavaScript to update Google Maps.  Ports have to be declared in their own module so let's create a GMaps.elm file and inside of it let's create two ports.  One for sending values from Elm to JavaScript and one to receive values in Elm from JavaScript:

```
port module GMaps exposing (..)

import SharedModels exposing (GMPos)


-- PORTS

port moveMap : GMPos -> Cmd msg

port mapMoved : (GMPos -> msg) -> Sub msg
```

Specifically, we are sending a latitude/longitude object to JavaScript to update our map and receiving new values in Elm when the map is moved independently.

Let's use our new ports in Main.elm:
```
import GMaps exposing (moveMap, mapMoved)

...

init : ( Model, Cmd Msg )
init =
    let
        knoxville =
            (GMPos 35.9335673 -84.016913)
    in
        ( Model knoxville 0 0, moveMap knoxville )

...

type Msg
    = MapMoved GMPos
    
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MapMoved newPos ->
            ( { model | pos = newPos }, Cmd.none )

...

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ mapMoved MapMoved ]

```

Above we now are sending values to JavaScript when our Model is initalized.  We also setup a Subscription to handle incoming values from JavaScript, create a new Msg type to handle when the map is moved and an update action to update our Model with the map's new position.  Now we need to update the JavaScript in our index.html to communicate with the Ports we just created.  Beneath the JavaScript initalizing our Google Maps instance, add the following:

```
       instance.ports.moveMap.subscribe(function(gmPos) {
            console.log("received", gmPos);
            var myLatlng = new google.maps.LatLng(gmPos);
            gmap.setCenter(myLatlng);
            marker.setPosition(myLatlng);
        });

        gmap.addListener('drag', function() {
          var newPos = {
            lat: gmap.getCenter().lat(),
            lng: gmap.getCenter().lng()
          };
          instance.ports.mapMoved.send(newPos);
        });
```
First we use our port moveMap to subscribe to data coming from Elm into JavaScript.  We log the value to the console, create a new Google Maps Latitude/Longitude object, and then set the center of our map to the new position and update are marker as well.  Secondly, we add a drag event to our map so that whenever the map is manually moved we calculate the new center position and send the value into Elm through our mapMoved port.

If you compile your application now with:

```
elm-make --warn src/Main.elm --output=main.js
```

You should have a working application that initializes and centers the map to Knoxville.  If you drag the map around, you should see the Latitude and Longitude values update as well.

Now your code should match [03](https://github.com/jenningstcj/Elm-Workshop/tree/03).

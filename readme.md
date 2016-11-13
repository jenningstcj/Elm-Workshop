## Elm Workshop

In this short tutorial we will walk through the steps to build the demo from [IntroToElm](https://jenningstcj.github.io/IntroToElm/Demos/GoogleMaps/index.html) where we cover many of the topics that exist in real world applications: Commands, Subscriptions, Http calls, JSON decoding, interop with JavaScript through Ports.  

Go ahead and download branch [01_Start](https://github.com/jenningstcj/Elm-Workshop/tree/01_Start) and follow along with the tutorial below.

### Install Dependencies

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
### Setup the Elm Architecture

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


After this, you should match [branch 02](https://github.com/jenningstcj/Elm-Workshop/tree/02) and have an application that compiles successfully.  You can compile the application from the root directory with:

```
elm-make --warn src/Main.elm --output=main.js
```

***


### Setup Model

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


### Setup Ports for JS Interop

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

You should have a working application (open the index.html a web browser) that initializes and centers the map to Knoxville.  If you drag the map around, you should see the Latitude and Longitude values update as well.

Now your code should match [branch 03](https://github.com/jenningstcj/Elm-Workshop/tree/03).


***


### Retrieve Data from HTTP

In preparation to make our HTTP call to retrieve live data about the International Space Station we need to add a few dependencies:
```
import Http
import Json.Decode exposing (..)
import Task
```

Next, let's model our data we want to retrieve.  The JSON object we will receive as many items, but we only want four.  If you want to see the full JSON object, open https://api.wheretheiss.at/v1/satellites/25544 in your browser.  We only want to use the latitude, longitude, altitude, and velocity.  Create a type alias for these items:
```
type alias ISS_JSON =
    { latitude : Float
    , longitude : Float
    , altitude : Float
    , velocity : Float
    }
```

HTTP calls in Elm consist of three main parts:  the function that performs the HTTP task, the Decoder to interpret and map the JSON to a type alias, and the Update Msg's to handle success and failures.  To perform an HTTP task, you need to structure the Http.Get call and provide the JSON decoder and url.  The HTTP call does not actually initiate communication until the task output by Http.get is 'performed'.  We will create a function called 'getLocation' to retrieve up-to-date information about the Space Station:

```
-- Http


getLocation : Cmd Msg
getLocation =
    let
        url =
            "https://api.wheretheiss.at/v1/satellites/25544"
    in
        (Http.get decodeISSPosition url)
            |> Task.perform FetchFail FetchSucceed
```

Perhaps one of the biggest difference in Elm that catches people new to the language off guard is that fact that you must parse/decode your JSON responses.  This is because the strictness of the language does not allow variability in data or data types.  The decoder for our ISS_JSON object is pretty simple and can use a built in decoder called 'object4' to decode our small object and then a 'float' decoder to parse each data item to the correct type:

```
decodeISSPosition : Decoder ISS_JSON
decodeISSPosition =
    object4 ISS_JSON
        ("latitude" := float)
        ("longitude" := float)
        ("altitude" := float)
        ("velocity" := float)
```

The last step in this branch is to add in our FetchFail and FetchSucceed update message types to handle the response of our Http getLocation function.  Go ahead and add the message types to our Msg type.  An Http task returns the JSON on a FetchSucceed and an Http.Error type on FetchFail:

```
type Msg
    = MapMoved GMPos
    | FetchSucceed ISS_JSON
    | FetchFail Http.Error
```

Now for the update functions:

```
        FetchSucceed newISSPos ->
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

        FetchFail _ ->
            ( model, Cmd.none )
```

One thing you may notice right at the start.  Our JSON is returning Float values, however, our altitude and velocity values on our Model are of type Int.  Therefore we have to write a little helper function - 'kilometersToMiles' - to use in our update function.  Lastly, our FetchFail will just swallow any errors for now and return the previous model.

The kilomtersToMiles conversion function is some simple math and a round down to the nearest integer:
```
kilometersToMiles : Float -> Int
kilometersToMiles km =
    km
        * 0.62137
        |> round
```

Now if you compile this with:
```
elm-make --warn src/Main.elm --output=main.js
```
You should have a successful compile, but if you open the index.html in a browser you may not see any difference yet because nothing is triggering the HTTP call to actually happen.  Your code should match [branch 04](https://github.com/jenningstcj/Elm-Workshop/tree/04).


***

### Subscribe to New Data

We have one last minor step to finish our appliction.  We need to setup a subscription to subscribe to an interval to poll for new data.  To do this, we will import Time, add a new subscription to our batch, and add an Update Msg type to handle our command.
```
import Time exposing (..)

...

Sub.batch
        [ mapMoved MapMoved
        , Time.every (5 * second) FetchPosition
        ]
```

Our Sub.batch is merely a list of subscriptions.  We already had the mapMoved subscription, now we had an interval with the Elm runtime will subscribe to.  To create an interval, we use Time.every and then a time amount.  Values such as second, minute, etc already exist so we build off that and use 5 * second to create 5 seconds.  Then call a new Msg type, FetchPosition.  Since FetchPosition is being called by the Time module, it needs to take Time as a parameter.

```
type Msg =
   ...
   | FetchPosition Time
```

Our update function for FetchPosition will return our previous model and then issue the command for getLocation.
```
        FetchPosition time ->
            ( model, getLocation )
```

Now you should be able to compile and run your application and have a full working web app that tracks the International Space Station.  Congratulations!
```
elm-make --warn src/Main.elm --output=main.js
```

Your code should match [branch 05](https://github.com/jenningstcj/Elm-Workshop/tree/05).

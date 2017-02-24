# Elm Workshop

In this short tutorial we will walk through the steps to build the demo from [IntroToElm](https://jenningstcj.github.io/IntroToElm/Demos/GoogleMaps/index.html) where we cover many of the topics that exist in real world applications: Commands, Subscriptions, Http calls, JSON decoding, interop with JavaScript through Ports.  

---

## Lesson 1: Getting Started

Go ahead and download branch [01_Start](https://github.com/jenningstcj/Elm-Workshop/tree/01_Start) and follow along with the tutorial below.
```
git clone https://github.com/jenningstcj/Elm-Workshop.git -b 01_Start Elm-Workshop
```

### Installing Dependencies

If you have installed Elm already, do so now with `npm install -g elm`.  This will install Elm globally and allow the usage of `elm-make`, `elm-reactor`, `elm-repl`, and `elm-package`.  

The **01_Start** branch of this repo is barebones with only an HTML file.  Navigate to the root of the `Elm-Workshop` directory in your terminal.  The quickest way to start a new Elm project is to type `elm-make` and hit Enter.  This will create an elm-package.json file and install the Core and Html libraries for Elm.  Then go ahead and install the Http library with the command:

```
elm-package install elm-lang/http -y
```

Now that we have a dependencies installed, create a `src` directory and update the elm-package.json line for source-directories to match the following:

```
"source-directories": [
  "src"
],
```
This is where we will put all of our Elm code.

### Setup the Elm Architecture

Then create a src/Main.elm file for your Elm application and set it up with the basic Elm Architecture for Html.program:

```
module Main exposing (..)

import Html exposing (Html, div, p, text)


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
    {}



-- INIT


init : ( Model, Cmd Msg )
init =
    ( Model, Cmd.none )



-- UPDATE


type Msg
    = Update


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

This is a barebones Elm program.  We have our `init`, `view`, `update`, and `subscriptions` functions.  We have an empty Model.  Our `init` function return an empty model, our `update` function returns the empty model, our `view` function returns a single Html Msg, and our `subscriptions` are set to none.  This is a fully compilable, yet empty program.  You can compile it with:

```
elm-make --warn src/Main.elm --output=main.js
```
Now if you open the `index.html` file in your browser you should see the Google Maps displayed and if you inspect the source code you will see the empty div returned by your Elm program.

This is the end of Lesson 1.  Your code should match [branch 02](https://github.com/jenningstcj/Elm-Workshop/tree/02).


---

## Lesson 2: Defining our Models and JS Interop

### Setup Model

Next we will define our Model.  Since part of our model will be used with Ports to facilitate JS interop, we will create that type alias in a separate file.  Go ahead and make a src/SharedModels.elm file.  We will share a type alias that contains a latitude and longitude to share with our Ports to also use in JavaScript with Google Maps.  In the src/SharedModels.elm file, declare the module and add the following type alias:

```
module SharedModels exposing (..)

type alias GMPos =
  { lat : Float
  , lng : Float
  }
```
Then in the src/Main.elm file, import the previously created type alias:

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

If you build the application now with `elm-make --warn src/Main.elm --output=main.js` and open the `index.html` file in a browser, you will see our html markup from our Elm application displaying the Latitude and Longitude of Knoxville, and an empty Altitude and Velocity.

### Setup Ports for JS Interop

Last step in this lesson will be to setup Ports to communicate with JavaScript to update Google Maps.  Ports have to be declared in their own module so let's create a src/GMaps.elm file and inside of it let's create two ports.  One for sending values from Elm to JavaScript and one to receive values in Elm from JavaScript:

```
port module GMaps exposing (..)

import SharedModels exposing (GMPos)


-- OUTGOING PORTS

port moveMap : GMPos -> Cmd msg

-- INCOMING PORTS

port mapMoved : (GMPos -> msg) -> Sub msg
```

Specifically, we are sending a latitude/longitude object to JavaScript to update our map and receiving new values in Elm when the map is moved independently.  An outgoing port takes a Model and executes a Cmd msg.  An incoming port takes a Model and a command and outputs a Subscription msg.

Let's use our new ports in src/Main.elm:
```
import GMaps exposing (moveMap, mapMoved)

```

Then let's update our `init` function to update our Google Maps position to our Knoxville coordinates upong program initialization.  In place of the `Cmd.none`, we will call our `moveMap` port and give it our Knoxville `GMPos` model.
```

init : ( Model, Cmd Msg )
init =
    let
        knoxville =
            (GMPos 35.9335673 -84.016913)
    in
        ( Model knoxville 0 0, moveMap knoxville )

```

Next, in our `subscriptions` function we will replace `Sub.none` with a`Sub.batch`, which takes a list of Subscription Msgs.  Specifically we will add our `mapMoved` port and give it a new Msg type to describe and Update action - `MapMovedUpdate`.  
```
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ mapMoved MapMovedUpdate ]

```

Now we need to create our `MapMovedUpdate` Msg type.  So replace the unused `Update` Msg type with `MapMovedUpdate GMPos`.  Remember our `mapMoved` port takes a `GMPos` model and output a Subscription.  Then add a `case` statement to our `update` function that takes the incoming `GMPos` and updates our internal model.
```
type Msg
    = MapMovedUpdate GMPos
    
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MapMovedUpdate newPos ->
            ( { model | pos = newPos }, Cmd.none )

```

Right now if we build our application we won't see anything different.  Our Elm application is trying to sent data out to update the map and it is listening for data coming in, but there isn't anything outside of our application that is receiving or sending data.  We need to update the JavaScript in our index.html to communicate with the Ports we just created.  Beneath the JavaScript initalizing our Google Maps instance, add the following:

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
First we use our port `moveMap` to subscribe to data coming from Elm into JavaScript.  We log the value to the console, create a new Google Maps Latitude/Longitude object, and then set the center of our map to the new position and update are marker as well.  Secondly, we add a drag event to our map so that whenever the map is manually moved we calculate the new center position and send the value into Elm through our `mapMoved` port.  It is two pub/sub relationships to handle two-way communication between JavaScript and our Elm application.

If you compile your application now with `elm-make --warn src/Main.elm --output=main.js` you should have a working application that initializes and centers the map to Knoxville.  If you drag the map around, you should see the Latitude and Longitude values update as well.

Now your code should match [branch 03](https://github.com/jenningstcj/Elm-Workshop/tree/03).


---

## Lesson 3: HTTP

### Retrieve Data from HTTP

In preparation to make our HTTP call to retrieve live data about the International Space Station we need to add a couple dependencies:
```
import Http
import Json.Decode exposing (..)
```

Next, let's model our data we want to retrieve.  The JSON object we will receive many items, but we only want four.  If you want to see the full JSON object, open https://api.wheretheiss.at/v1/satellites/25544 in your browser.  We only want to use the latitude, longitude, altitude, and velocity.  Create a type alias for these items:
```
type alias ISS_JSON =
    { latitude : Float
    , longitude : Float
    , altitude : Float
    , velocity : Float
    }
```

HTTP calls in Elm consist of three main parts:  the function that performs the HTTP command, the Decoder to interpret and map the JSON to a type alias, and the Update Msg's to handle success and failures.  To perform an HTTP command, you need to structure the `Http.get` call and provide the url and JSON decoder.  The HTTP call does not actually initiate communication until we tell Elm to execute the command with `Http.send`.  We will create a new `-- Http` section in our application to group our Http stuff.  Then create a function called 'getLocation' to retrieve up-to-date information about the Space Station:

```
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
```

Perhaps one of the biggest difference in Elm that catches newcomers to the language off guard is the fact that you must parse/decode your JSON responses.  This is because the strictness of the language does not allow variability in data or data types.  The decoder for our ISS_JSON object is pretty simple and can use a built in decoder called 'map4' to decode our small object and then a 'float' decoder to parse each field to the correct type:

```
decodeISSPosition : Decoder ISS_JSON
decodeISSPosition =
    map4 ISS_JSON
        (field "latitude" float)
        (field "longitude" float)
        (field "altitude" float)
        (field "velocity" float)
```

There are other ways to decode JSON data, including options for handling dynamic data.  In the case of dynamic data you'd want to use the `oneOf` function and provide a list of decoders.  The compiler would then try each decoder in the list until one succeeded.

The last step in this lesson is to add in our `LoadData` update message type to handle the response of our Http getLocation function.  An Http call returns a `Result` type with an `error` option and a `value` option.  This let's us use one update function for handling both successes and failures. 

```
type Msg
    = MapMoved GMPos
    | LoadData (Result Http.Error ISS_JSON)
```

Now we can pattern match on whether the LoadData contains an `Ok` type or an `Err` type.  The `Ok` type will contain our decoded data and the `Err` type will contain the error message.  An `Err` type will be returned whenever there is an error executing the Http call or whenever there is a problem decoding the JSON.  In this example we won't act upon the `Err` state, but in real applications you may log it or handle it in some way.  Our `Ok` branch updates the `GMPos` field on our model along with the velocity and altitude.  Since the data returned is in Kilometers per hour, we are making a quick conversion with a helper function you will see next.

```
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

Now if you compile this with `elm-make --warn src/Main.elm --output=main.js` you should have a successful compile, but if you open the index.html in a browser you may not see any difference yet because nothing is triggering the HTTP call to actually happen.  Your code should match [branch 04](https://github.com/jenningstcj/Elm-Workshop/tree/04).


---

## Lesson 4: Subscriptions

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

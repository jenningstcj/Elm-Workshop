## Elm Workshop

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


After this, you should match branch [02](https://github.com/jenningstcj/Elm-Workshop/tree/02)

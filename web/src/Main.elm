port module Main exposing (..)

import Browser
import Browser.Events as BrowserEvent
import FormatNumber as F
import FormatNumber.Locales as F
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as Event
import Json.Decode as Decode



-- PORTS


port setSettings : Settings -> Cmd msg


main : Program Settings Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias Model =
    { isOpen : Bool
    , settings : Settings
    }


type alias Settings =
    { viscosity : Float
    , velocityDissipation : Float
    , diffusionIterations : Int
    , pressureIterations : Int
    , lineLength : Float
    , lineWidth : Float
    , lineBeginOffset : Float
    , noiseChannel1 : Noise
    , noiseChannel2 : Noise
    }


type alias Noise =
    { scale : Float
    , multiplier : Float
    , offset1 : Float
    , offset2 : Float
    , offsetIncrement : Float
    , blendDuration : Float
    }


init : Settings -> ( Model, Cmd Msg )
init initialSettings =
    let
        model =
            { isOpen = False
            , settings = initialSettings
            }
    in
    ( model, setSettings model.settings )



-- UPDATE


type Msg
    = ToggleControls
    | SaveSetting SettingMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleControls ->
            ( { model | isOpen = not model.isOpen }, Cmd.none )

        SaveSetting settingToUpdate ->
            let
                newSettings =
                    updateSettings settingToUpdate model.settings
            in
            ( { model | settings = newSettings }
            , setSettings newSettings
            )


type SettingMsg
    = SetViscosity Float
    | SetVelocityDissipation Float
    | SetDiffusionIterations Int
    | SetPressureIterations Int
    | SetLineLength Float
    | SetLineWidth Float
    | SetLineBeginOffset Float
    | SetNoiseChannel1 NoiseMsg
    | SetNoiseChannel2 NoiseMsg


type NoiseMsg
    = SetNoiseScale Float
    | SetNoiseMultiplier Float
    | SetNoiseOffset1 Float
    | SetNoiseOffset2 Float
    | SetNoiseOffsetIncrement Float
    | SetNoiseBlendDuration Float


updateSettings : SettingMsg -> Settings -> Settings
updateSettings msg settings =
    case msg of
        SetViscosity newViscosity ->
            { settings | viscosity = newViscosity }

        SetVelocityDissipation newVelocityDissipation ->
            { settings | velocityDissipation = newVelocityDissipation }

        SetDiffusionIterations newDiffusionIterations ->
            { settings | diffusionIterations = newDiffusionIterations }

        SetPressureIterations newPressureIterations ->
            { settings | pressureIterations = newPressureIterations }

        SetLineLength newLineLength ->
            { settings | lineLength = newLineLength }

        SetLineWidth newLineWidth ->
            { settings | lineWidth = newLineWidth }

        SetLineBeginOffset newLineBeginOffset ->
            { settings | lineBeginOffset = newLineBeginOffset }

        SetNoiseChannel1 noiseMsg ->
            { settings | noiseChannel1 = updateNoise noiseMsg settings.noiseChannel1 }

        SetNoiseChannel2 noiseMsg ->
            { settings | noiseChannel2 = updateNoise noiseMsg settings.noiseChannel2 }


updateNoise : NoiseMsg -> Noise -> Noise
updateNoise msg noise =
    case msg of
        SetNoiseScale newScale ->
            { noise | scale = newScale }

        SetNoiseMultiplier newMultiplier ->
            { noise | multiplier = newMultiplier }

        SetNoiseOffset1 newOffset ->
            { noise | offset1 = newOffset }

        SetNoiseOffset2 newOffset ->
            { noise | offset2 = newOffset }

        SetNoiseOffsetIncrement newOffsetIncrement ->
            { noise | offsetIncrement = newOffsetIncrement }

        SetNoiseBlendDuration newBlendDuration ->
            { noise | blendDuration = newBlendDuration }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.isOpen then
        BrowserEvent.onKeyDown toggleControlsOnEscape

    else
        Sub.none


toggleControlsOnEscape : Decode.Decoder Msg
toggleControlsOnEscape =
    Decode.field "key" Decode.string
        |> Decode.andThen
            (\string ->
                if string == "Escape" then
                    Decode.succeed ToggleControls

                else
                    Decode.fail ""
            )



-- VIEW


type alias Control value =
    { title : String
    , description : String
    , input : Input value
    }


type Input number
    = Slider
        { min : number
        , max : number
        , step : number
        , value : number
        , onInput : String -> Msg
        , toString : number -> String
        }


view : Model -> Html Msg
view model =
    Html.div []
        [ Html.div
            [ HA.class "control-panel"
            , HA.class <|
                if model.isOpen then
                    "visible"

                else
                    ""
            ]
            [ Html.div
                [ HA.class "control-container" ]
                [ viewSettings model.settings ]
            ]
        , Html.footer []
            [ Html.ul [ HA.class "nav" ]
                [ Html.li []
                    [ Html.button
                        [ Event.onClick ToggleControls
                        , HA.class <|
                            if model.isOpen then
                                "active"

                            else
                                ""
                        ]
                        [ Html.text "Controls" ]
                    ]
                , Html.li []
                    [ Html.a
                        [ HA.href "https://github.com/sandydoo/" ]
                        [ Html.text "© 2021 Sander Melnikov" ]
                    ]
                , Html.li []
                    [ Html.a
                        [ HA.href "https://github.com/sandydoo/flux/blob/main/LICENSE" ]
                        [ Html.text "Licensed under MIT" ]
                    ]
                ]
            ]
        ]


viewSettings : Settings -> Html Msg
viewSettings settings =
    Html.ul
        [ HA.class "control-list" ]
        [ Html.div
            [ HA.class "col-span-2-md" ]
            [ Html.button
                [ Event.onClick ToggleControls, HA.class "text-secondary" ]
                [ Html.text "← Back" ]
            , Html.h2 [] [ Html.text "Fluid simulation" ]
            ]
        , viewControl <|
            Control
                "Viscosity"
                """
                A viscous fluid resists any change to its velocity.
                It spreads out and diffuses any force applied to it.
                """
                (Slider
                    { min = 0.1
                    , max = 4.0
                    , step = 0.1
                    , value = settings.viscosity
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetViscosity
                                |> SaveSetting
                    , toString = formatFloat 1
                    }
                )
        , viewControl <|
            Control
                "Velocity diffusion"
                """
                Velocity should decrease, or dissipate, as it travels through a fluid.
                """
                (Slider
                    { min = 0.0
                    , max = 2.0
                    , step = 0.1
                    , value = settings.velocityDissipation
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetVelocityDissipation
                                |> SaveSetting
                    , toString = formatFloat 1
                    }
                )
        , viewControl <|
            Control
                "Diffusion iterations"
                """
                Viscous fluids dissipate velocity through a process called “diffusion”.
                Each iteration enchances this effect and the diffusion strength is controlled by the fluid’s viscosity.
                """
                (Slider
                    { min = 0
                    , max = 30
                    , step = 1
                    , value = settings.diffusionIterations
                    , onInput =
                        \value ->
                            String.toInt value
                                |> Maybe.withDefault 0
                                |> SetDiffusionIterations
                                |> SaveSetting
                    , toString = String.fromInt
                    }
                )
        , viewControl <|
            Control
                "Pressure iterations"
                """
                Applying a force to fluid creates pressure as the fluid pushes back.
                Calculating pressure is expensive, but the fluid will look unrealistic with fewer than 20 iterations.
                """
                (Slider
                    { min = 0
                    , max = 60
                    , step = 1
                    , value = settings.pressureIterations
                    , onInput =
                        \value ->
                            String.toInt value
                                |> Maybe.withDefault 0
                                |> SetPressureIterations
                                |> SaveSetting
                    , toString = String.fromInt
                    }
                )
        , Html.div
            [ HA.class "col-span-2-md" ]
            [ Html.h2 [] [ Html.text "Look" ] ]
        , viewControl <|
            Control
                "Line length"
                """
                The maximum length of a line.
                """
                (Slider
                    { min = 1.0
                    , max = 500.0
                    , step = 1.0
                    , value = settings.lineLength
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetLineLength
                                |> SaveSetting
                    , toString = formatFloat 0
                    }
                )
        , viewControl <|
            Control
                "Line width"
                """
                The maximum width of a line.
                """
                (Slider
                    { min = 1.0
                    , max = 20.0
                    , step = 0.1
                    , value = settings.lineWidth
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetLineWidth
                                |> SaveSetting
                    , toString = formatFloat 1
                    }
                )
        , viewControl <|
            Control
                "Line fade offset"
                """
                The point along a line when it begins to fade out.
                """
                (Slider
                    { min = 0.0
                    , max = 1.0
                    , step = 0.01
                    , value = settings.lineBeginOffset
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetLineBeginOffset
                                |> SaveSetting
                    , toString = formatFloat 2
                    }
                )
        , Html.div
            [ HA.class "col-span-2-md" ]
            [ Html.h2 [] [ Html.text "Noise" ] ]
        , viewNoiseChannel "Channel 1" SetNoiseChannel1 settings.noiseChannel1
        , viewNoiseChannel "Channel 2" SetNoiseChannel2 settings.noiseChannel2
        ]


viewNoiseChannel title setNoiseChannel noiseChannel =
    Html.div
        [ HA.class "control-list-single" ]
        [ Html.div []
            [ Html.h4 [] [ Html.text title ]
            , Html.p [ HA.class "control-description" ] [ Html.text "Simplex noise" ]
            ]
        , viewControl <|
            Control
                "Scale"
                ""
                (Slider
                    { min = 0.1
                    , max = 30.0
                    , step = 0.1
                    , value = noiseChannel.scale
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetNoiseScale
                                |> setNoiseChannel
                                |> SaveSetting
                    , toString = formatFloat 1
                    }
                )
        , viewControl <|
            Control
                "Strength"
                ""
                (Slider
                    { min = 0.0
                    , max = 3.0
                    , step = 0.1
                    , value = noiseChannel.multiplier
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetNoiseMultiplier
                                |> setNoiseChannel
                                |> SaveSetting
                    , toString = formatFloat 1
                    }
                )
        , viewControl <|
            Control
                "Offset 1"
                ""
                (Slider
                    { min = 0.0
                    , max = 100.0
                    , step = 1.0
                    , value = noiseChannel.offset1
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetNoiseOffset1
                                |> setNoiseChannel
                                |> SaveSetting
                    , toString = formatFloat 1
                    }
                )
        , viewControl <|
            Control
                "Offset 2"
                ""
                (Slider
                    { min = 0.0
                    , max = 100.0
                    , step = 1.0
                    , value = noiseChannel.offset2
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetNoiseOffset2
                                |> setNoiseChannel
                                |> SaveSetting
                    , toString = formatFloat 1
                    }
                )
        , viewControl <|
            Control
                "Offset increment"
                ""
                (Slider
                    { min = 0.0
                    , max = 1000.0
                    , step = 1.0
                    , value = noiseChannel.offsetIncrement
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetNoiseOffsetIncrement
                                |> setNoiseChannel
                                |> SaveSetting
                    , toString = formatFloat 1
                    }
                )
        , viewControl <|
            Control
                "Blend duration"
                ""
                (Slider
                    { min = 0.1
                    , max = 10.0
                    , step = 0.1
                    , value = noiseChannel.blendDuration
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetNoiseBlendDuration
                                |> setNoiseChannel
                                |> SaveSetting
                    , toString = formatFloat 1
                    }
                )
        ]


viewControl : Control number -> Html Msg
viewControl { title, description, input } =
    let
        id =
            toKebabcase title
    in
    Html.li [ HA.class "control" ]
        [ Html.label
            [ HA.for id ]
            [ Html.h3
                [ HA.class "control-title" ]
                [ Html.text title ]
            , Html.p
                [ HA.class "control-description" ]
                [ Html.text description ]
            , Html.div [ HA.class "control-slider" ] <|
                case input of
                    Slider slider ->
                        [ Html.input
                            [ HA.id id
                            , HA.type_ "range"
                            , HA.min <| slider.toString slider.min
                            , HA.max <| slider.toString slider.max
                            , HA.step <| slider.toString slider.step
                            , HA.value <| slider.toString slider.value
                            , Event.onInput slider.onInput
                            ]
                            []
                        , Html.span
                            [ HA.class "control-value" ]
                            [ Html.text <| slider.toString slider.value ]
                        ]
            ]
        ]


formatFloat : Int -> Float -> String
formatFloat decimals value =
    F.format
        { decimals = F.Exact decimals
        , system = F.Western
        , thousandSeparator = ","
        , decimalSeparator = "."
        , negativePrefix = "−"
        , negativeSuffix = ""
        , positivePrefix = ""
        , positiveSuffix = ""
        , zeroPrefix = ""
        , zeroSuffix = ""
        }
        value


toKebabcase : String -> String
toKebabcase =
    let
        -- This only converts titles separated by spaces
        kebabify char =
            if char == ' ' then
                '-'

            else
                Char.toLower char
    in
    String.map kebabify

module Main exposing (Model, Msg(..), init, main, update, view)

-- import Html.Attributes exposing (src)

import Browser
import Css exposing (..)
import Debounce exposing (Debounce)
import Graphql.Http
import Graphql.Operation exposing (RootQuery)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, with)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (class, css, placeholder, src)
import Html.Styled.Events exposing (onBlur, onInput)
import ParseWhere exposing (..)
import Quest.Enum.ComparisonOperator as Comparitor
import Quest.InputObject exposing (IntFilterType)
import Quest.Object
import Quest.Object.Armor as Armor
import Quest.Object.Weapon as Weapon
import Quest.Query as Query
import Quest.Scalar exposing (Id(..))
import Quest.Union
import Quest.Union.Item as Item
import RemoteData exposing (RemoteData)
import Task



---- MODEL ----


type alias Model =
    { value : String
    , debounce : Debounce String
    , items : { armors : List ArmorSpec, weapons : List WeaponSpec }
    }


init : ( Model, Cmd Msg )
init =
    ( { value = ""
      , debounce = Debounce.init
      , items = { armors = [], weapons = [] }
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = GotResponse (RemoteData (Graphql.Http.Error Response) Response)
    | UpdateSearch String
    | DebounceMsg Debounce.Msg
    | Saved String
    | NoOp


type alias ArmorSpec =
    { name : String
    , dt : Int
    , value : Int
    , weight : Int
    , traits : List String
    }


type alias WeaponSpec =
    { name : String
    , dmg : List String
    , acc : Int
    , str : Int
    , mag : Int
    , ammo : String
    , value : Int
    , weight : Int
    , traits : List String
    }


type Item
    = WeaponDetails WeaponSpec
    | ArmorDetails ArmorSpec


type alias Response =
    List Item


presentIfJust : Maybe a -> Graphql.OptionalArgument.OptionalArgument a
presentIfJust m =
    case m of
        Nothing ->
            Absent

        Just a ->
            Present a


query : ParseWhere.FilterDict -> SelectionSet (List Item) RootQuery
query filterDict =
    let
        _ =
            Debug.log "filterdict" filterDict
    in
    Query.findItems
        (\optionals ->
            { optionals
                | where_ =
                    Present
                        { name = presentIfJust <| nameDecoder filterDict
                        , limit = presentIfJust <| limitDecoder filterDict
                        , acc = presentIfJust <| comparitorDecoder "acc" filterDict
                        , value = presentIfJust <| comparitorDecoder "value" filterDict
                        , str = presentIfJust <| comparitorDecoder "str" filterDict
                        , mag = presentIfJust <| comparitorDecoder "mag" filterDict
                        , weight = presentIfJust <| comparitorDecoder "weight" filterDict
                        , dt = presentIfJust <| comparitorDecoder "dt" filterDict
                        }
            }
        )
        itemSelection


itemSelection : SelectionSet Item Quest.Union.Item
itemSelection =
    Item.fragments
        { onArmor = SelectionSet.map ArmorDetails armorSelection
        , onWeapon = SelectionSet.map WeaponDetails weaponSelection
        }


weaponSelection : SelectionSet WeaponSpec Quest.Object.Weapon
weaponSelection =
    SelectionSet.succeed WeaponSpec
        |> with Weapon.name
        |> with Weapon.dmg
        |> with Weapon.acc
        |> with Weapon.str
        |> with Weapon.mag
        |> with Weapon.ammo
        |> with Weapon.value
        |> with Weapon.weight
        |> with Weapon.traits


armorSelection : SelectionSet ArmorSpec Quest.Object.Armor
armorSelection =
    SelectionSet.map5 ArmorSpec
        Armor.name
        Armor.dt
        Armor.value
        Armor.weight
        Armor.traits


makeRequest : String -> Cmd Msg
makeRequest searchString =
    buildQuery searchString
        |> Graphql.Http.queryRequest "http://localhost:4000/quest"
        |> Graphql.Http.send (RemoteData.fromResult >> GotResponse)


buildQuery : String -> SelectionSet (List Item) RootQuery
buildQuery searchString =
    query (parse searchString)


debounceConfig : Debounce.Config Msg
debounceConfig =
    { strategy = Debounce.later 1000
    , transform = DebounceMsg
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotResponse response ->
            case response of
                RemoteData.Success items ->
                    let
                        defaultValue =
                            { armors = [], weapons = [] }

                        combiner item acc =
                            case item of
                                ArmorDetails armor ->
                                    { acc | armors = armor :: acc.armors }

                                WeaponDetails weapon ->
                                    { acc | weapons = weapon :: acc.weapons }

                        folded =
                            List.foldl combiner defaultValue items
                    in
                    ( { model | items = folded }, Cmd.none )

                RemoteData.Loading ->
                    ( model, Cmd.none )

                RemoteData.NotAsked ->
                    ( model, Cmd.none )

                RemoteData.Failure e ->
                    let
                        _ =
                            Debug.log "error" e
                    in
                    ( model, Cmd.none )

        UpdateSearch search ->
            let
                ( debounce, cmd ) =
                    Debounce.push debounceConfig search model.debounce
            in
            ( { model | value = search, debounce = debounce }, cmd )

        DebounceMsg msg_ ->
            let
                ( debounce, cmd ) =
                    Debounce.update
                        debounceConfig
                        (Debounce.takeLast save)
                        msg_
                        model.debounce
            in
            ( { model | debounce = debounce }, cmd )

        Saved s ->
            ( model, makeRequest s )

        NoOp ->
            ( model, Cmd.none )


save : String -> Cmd Msg
save s =
    Task.perform Saved (Task.succeed s)



---- VIEW ----


viewItem : Item -> Html Msg
viewItem item =
    case item of
        WeaponDetails weapon ->
            viewWeapon weapon

        ArmorDetails armor ->
            viewArmor armor


viewWeapon : WeaponSpec -> Html Msg
viewWeapon weapon =
    li []
        [ text
            (weapon.name
                ++ " dmg: "
                ++ String.join " " weapon.dmg
                ++ " acc: "
                ++ String.fromInt weapon.acc
                ++ " str: "
                ++ String.fromInt weapon.str
                ++ " mag: "
                ++ String.fromInt weapon.mag
                ++ " ammo: "
                ++ weapon.ammo
                ++ " value: "
                ++ String.fromInt weapon.value
                ++ " weight: "
                ++ String.fromInt weapon.weight
            )
        ]


viewArmor : ArmorSpec -> Html Msg
viewArmor armor =
    li []
        [ text
            (armor.name
                ++ " caps: "
                ++ String.fromInt armor.dt
                ++ " dt: "
                ++ String.fromInt armor.dt
                ++ " weight: "
                ++ String.fromInt armor.weight
            )
        ]


view : Model -> Html Msg
view model =
    let
        _ =
            Debug.log "items" model.items
    in
    div
        [ css
            [ maxWidth (px 600)
            , margin auto
            ]
        ]
        [ h1 [] [ text "Quest" ]
        , input [ class "input", placeholder "Search...", onInput UpdateSearch ] []
        , ul [] []
        ]



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view >> toUnstyled
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }

-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Quest.Object.Armor exposing (dt, id, name, traits, type_, value, weight)

import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode
import Quest.Enum.ArmorType
import Quest.InputObject
import Quest.Interface
import Quest.Object
import Quest.Scalar
import Quest.ScalarCodecs
import Quest.Union


{-| -}
id : SelectionSet Quest.ScalarCodecs.Id Quest.Object.Armor
id =
    Object.selectionForField "ScalarCodecs.Id" "id" [] (Quest.ScalarCodecs.codecs |> Quest.Scalar.unwrapCodecs |> .codecId |> .decoder)


{-| -}
name : SelectionSet String Quest.Object.Armor
name =
    Object.selectionForField "String" "name" [] Decode.string


{-| -}
type_ : SelectionSet Quest.Enum.ArmorType.ArmorType Quest.Object.Armor
type_ =
    Object.selectionForField "Enum.ArmorType.ArmorType" "type" [] Quest.Enum.ArmorType.decoder


{-| -}
dt : SelectionSet Int Quest.Object.Armor
dt =
    Object.selectionForField "Int" "dt" [] Decode.int


{-| -}
value : SelectionSet Int Quest.Object.Armor
value =
    Object.selectionForField "Int" "value" [] Decode.int


{-| -}
weight : SelectionSet Int Quest.Object.Armor
weight =
    Object.selectionForField "Int" "weight" [] Decode.int


{-| -}
traits : SelectionSet (List String) Quest.Object.Armor
traits =
    Object.selectionForField "(List String)" "traits" [] (Decode.string |> Decode.list)
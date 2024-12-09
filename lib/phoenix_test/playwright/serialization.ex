defmodule PhoenixTest.Playwright.Serialization do
  @moduledoc false

  require Logger

  def serialize(nil) do
    %{value: %{v: "undefined"}, handles: []}
  end

  def deserialize({:ok, value}) do
    deserialize(value)
  end

  def deserialize(value) when is_map(value) do
    case value do
      %{a: list} ->
        Enum.map(list, &deserialize/1)

      %{b: boolean} ->
        boolean

      %{n: number} ->
        number

      %{o: object} ->
        object
        |> Map.new(fn item -> {item.k, deserialize(item.v)} end)
        |> deep_atomize_keys()

      %{s: string} ->
        string

      %{v: "null"} ->
        nil

      %{v: "undefined"} ->
        nil

      %{ref: _} ->
        :ref_not_resolved
    end
  end

  def deserialize(value) when is_list(value) do
    Enum.map(value, &deserialize(&1))
  end

  defp deep_atomize_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_map(v) ->
        {to_atom(k), deep_atomize_keys(v)}

      {k, list} when is_list(list) ->
        {to_atom(k), Enum.map(list, fn v -> deep_atomize_keys(v) end)}

      {k, v} ->
        {to_atom(k), v}
    end)
  end

  defp deep_atomize_keys(other), do: other

  defp to_atom(nil), do: raise(ArgumentError, message: "Unable to convert nil into an atom")
  defp to_atom(s) when is_binary(s), do: String.to_atom(s)
  defp to_atom(a) when is_atom(a), do: a
end

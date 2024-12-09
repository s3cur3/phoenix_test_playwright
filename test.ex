defmodule MyFeatureTest do
  use PhoenixTest.Case,
    async: true,
    parameterize: [%{playwright: [browser: :chromium]}, %{playwright: [browser: :firefox]}]

    test "heading", %{conn: conn} do
      conn
      |> visit("/")
      |> assert_has("h1", text: "Heading")
    end
  end
end
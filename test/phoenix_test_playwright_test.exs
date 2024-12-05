defmodule PhoenixTestPlaywrightTest do
  use ExUnit.Case
  doctest PhoenixTestPlaywright

  test "greets the world" do
    assert PhoenixTestPlaywright.hello() == :world
  end
end

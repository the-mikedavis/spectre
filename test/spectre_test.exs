defmodule SpectreTest do
  use ExUnit.Case
  doctest Spectre

  test "greets the world" do
    assert Spectre.hello() == :world
  end
end

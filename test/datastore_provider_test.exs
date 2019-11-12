defmodule DatastoreProviderTest do
  use ExUnit.Case
  doctest DatastoreProvider

  test "greets the world" do
    assert DatastoreProvider.hello() == :world
  end
end

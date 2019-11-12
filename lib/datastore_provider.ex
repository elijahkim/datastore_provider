defmodule DatastoreProvider do
  @behaviour Config.Provider

  @moduledoc """
  DatastoreProvider is a [release config
  provider](https://hexdocs.pm/elixir/Config.Provider.html).

  The provider takes key value pairs in google's datastore and turns them into
  application variables. The provider takes the key and turns them into a config
  key and sets the value to whatever value is in the datastore. For example,
  a key value like `foo/bar/baz => "abc123"` will turn into `config :foo, :bar,
  baz: "abc123"`

  You can use this buy adding this snippet to the release section in your mix
  project.
  ```
    config_providers: [{DatastoreProvider, [<table name>]}]
  ```

  Lastly, you will need to provide the credentials to your datstore in your
  config. You can do this buy the methods listed in
  (goth)[https://github.com/peburrows/goth]. If you're running on GAE you should
  already have credentials in your host machine and can pick it up with the
  environment variable by setting the config as follows:

  ```
    config :goth, json: {:system, "GOOGLE_APPLICATION_CREDENTIALS"}
  ```

  One gotcha is that if you're using module names as keys you have to fully
  namespace your key or else it won't be evaluated as a module. For example if
  you want to create a key as `config :my_app, MyApp.Repo` you should make the
  key `myapp/Elixir.MyApp.Repo`.
  """

  def init(table) when is_binary(table), do: table

  def load(config, table) do
    {:ok, _} = Application.ensure_all_started(:diplomat)

    runtime_config =
      table
      |> fetch_entities()
      |> transform()

    Config.Reader.merge(config, runtime_config)
  end

  def fetch_entities(table) do
    Diplomat.Query.new(
      "select * from `#{table}`"
    ) |> Diplomat.Query.execute
  end

  def transform(items) when is_list(items) do
    Enum.map(items, &transform/1)
  end

  def transform(%{properties: properties}) do
    [{key, %{value: value}}] = Map.to_list(properties)

    String.split(key, "/")
    |> to_config(value)
  end

  def to_config([app, key], value) do
    {String.to_atom(app), [{String.to_atom(key), value}]}
  end

  def to_config([app, key, v], value) do
    {
      String.to_atom(app), [{
        String.to_atom(key), [{String.to_atom(v), value}]
      }]
    }
  end
end

defmodule Spectre do
  @moduledoc "Helper functions for determining specs"

  @dial Application.get_env(:spectre, :dialyzer_client, :dialyzer)
  @dial_plt Application.get_env(:spectre, :dialyzer_plt_client, :dialyzer_plt)

  @type t_signature :: {{module(), atom(), non_neg_integer()}, list(), list()}
  @type t_quote :: {atom(), list(), list()}

  @spec source_modules() :: [module()]
  def source_modules do
    {:ok, modules} =
      Mix.Project.config()
      |> Keyword.fetch!(:app)
      |> :application.get_key(:modules)

    modules
  end

  @spec run() :: :ok
  def run do
    plt = Dialyxir.Project.plt_file()

    add_project_to_plt(plt, beams())

    Enum.each(source_modules(), &run(plt, &1))
  end

  @spec run(:dialyzer_plt.plt(), module()) :: :ok
  defp run(plt, module) do
    {:value, signatures} = @dial_plt.lookup_module(plt, mod)

    signatures
    # remove those that already have specs
    |> Enum.reject(fn {mfa, _r, _d} -> already_have_spec?(plt, mfa) end)
    |> Enum.map(fn {mfa, _r, _d} = sig ->
      {mfa, sig_to_spec_string(sig)}
    end)

    :ok
  end

  # returns true if a function already has a spec defined, false otherwise
  @spec already_have_spec?(:dialyzer_plt.plt(), mfa()) :: boolean()
  defp already_have_spec?(plt, mfa) do
    case @dial_plt.lookup_contract(plt, mfa) do
      :none -> true
      _ -> false
    end
  end

  @spec beams() :: [Path.t()]
  def beams do
    Mix.Project.compile_path()
    |> Path.join("*.beam")
    |> Path.wildcard()
  end

  @spec add_project_to_plt(Path.t(), [Path.t()]) :: :ok | {:error, any()}
  def add_project_to_plt(plt, files) do
    [
      check_plt: false,
      analysis_type: :plt_add,
      init_plt: erlify_path(plt),
      files: Enum.map(files, &erlify_path/1)
    ]
    |> @dial.run()
    |> case do
      [] -> :ok
      warnings -> {:error, warnings}
    end
  end

  @spec fun(integer()) :: map()
  def fun(num), do: %{num => num}

  @spec sig_to_spec_string(t_signature()) :: t_quote()
  def sig_to_spec_string({{_module, fun, _arity}, range, domain}) do
    inputs =
      domain
      |> Enum.map(&:erl_types.t_to_string/1)
      |> Enum.join(", ")

    "@spec #{fun}(#{inputs}) :: #{:erl_types.t_to_string(range)}"
  end

  @doc """
  Produces a quote for a `@spec` given a function's signature.
  """
  @spec sig_to_spec_quote(t_signature()) :: t_quote()
  def sig_to_spec_quote({{_module, fun, _arity}, _range, _domain}) do
    {:@, [context: Elixir, import: Kernel],
      [
        {:spec, [context: Elixir],
          [{:::, [], [{fun, [], [
            # TODO replace with quoted form of input
            {:integer, [], []}]},
            # TODO replace with quoted form of output
            {:map, [], []}
          ]}]}
      ]}
  end

  @spec erlify_path(Path.t()) :: :file.filename()
  def erlify_path(path) do
    :unicode.characters_to_list(path, :file.native_name_encoding())
  end
end

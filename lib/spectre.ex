defmodule Spectre do
  @moduledoc "Helper functions for determining specs"

  @dial Application.get_env(:spectre, :dialyzer_client, :dialyzer)
  @dial_plt Application.get_env(:spectre, :dialyzer_plt_client, :dialyzer_plt)

  @type t_signature :: {mfa(), :erl_types.erl_type(), [:erl_types.erl_type()]}

  @doc """
  Return a list of source modules which the current project defines
  """
  @spec source_modules() :: [module()]
  def source_modules do
    {:ok, modules} =
      Mix.Project.config()
      |> Keyword.fetch!(:app)
      |> :application.get_key(:modules)

    modules
  end

  @doc """
  Ensures that the PLT

  - exists
  - contains the current project

  Once it has passed those checks, the loaded PLT is returned.

  Loaded PLTs may be used to lookup contracts and signatures.
  """
  @spec prepare_plt() :: {:ok, :dialyzer_plt.plt()}
  def prepare_plt do
    file = plt_file()

    unless File.exists?(file) do
      File.copy!(Dialyxir.Project.plt_file(), file)
    end

    add_project_to_plt(file, beams())

    {:ok, @dial_plt.from_file(file)}
  end

  @spec lookup(:dialyzer_plt.plt(), mfa(), Keyword.t()) :: {:ok, String.t()} | :error
  def lookup(plt, mfa, output_type) do
    output_fun =
      case output_type do
        [erl_type: true] ->
          fn func ->
            func
            |> Kernel.inspect(limit: :infinity)
            |> Code.format_string!()
          end

        [erlang: true] ->
          fn {{_mod, f, _a}, range, domain} ->
            dom =
              domain
              |> Enum.map(&:erl_types.t_to_string/1)
              |> Enum.join(", ")

            "#{f}(#{dom}) -> #{:erl_types.t_to_string(range)}"
          end

        _ -> &sig_to_spec_string/1
      end

    case @dial_plt.lookup(plt, mfa) do
      {:value, {range, domain}} ->
        output_fun.({mfa, range, domain})

      :none ->
        :error
    end
  end

  def run(plt), do: Enum.map(source_modules(), &run(plt, &1))

  defp run(plt, module) do
    {:value, signatures} = @dial_plt.lookup_module(plt, module)

    signatures
    # remove those that already have specs
    |> Enum.reject(fn {mfa, _r, _d} -> already_have_spec?(plt, mfa) end)
    |> Enum.map(fn {_mfa, _r, _d} = sig ->
      sig
      # {mfa, sig_to_spec_string(sig)}
    end)
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

  @spec sig_to_spec_string(t_signature()) :: String.t()
  def sig_to_spec_string({{_module, fun, _arity}, range, domain}) do
    ExTypes.Spec.iolist(fun, domain, range)
  end

  @spec erlify_path(Path.t()) :: :file.filename()
  def erlify_path(path) do
    :unicode.characters_to_list(path, :file.native_name_encoding())
  end

  @spec plt_file() :: Path.t()
  def plt_file do
    Dialyxir.Project.plt_file()
    |> String.replace("dialyxir", "spectre")
    |> String.replace("deps-", "")
  end
end

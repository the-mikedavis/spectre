defmodule Mix.Tasks.Spectre do
  use Mix.Task

  @version Mix.Project.config()[:version]

  @shortdoc "Generate specs on functions"
  @moduledoc """
  # Spectre

  Version #{@version}

  Spectre creates `@spec`s on functions that don't have any. Spectre
  does not perform any static type checking, and will try to spec every
  function even if the code will create run-time errors.

  ## Usage

  You can use spectre to lookup the success typing on any function in the
  PLT.

      mix spectre <module> <function> <arity>

  E.g.

      mix spectre File read 1

  If you want to spec your entire project, you can do so with

      mix spectre

  Recommended usage:

  1. Commit all your changes in your project directory.
  2. `mix spectre` in the project root.
  3. Use `git diff` to view the new specs.
  """
  @preferred_cli_env :test
  @recursive false

  @switches [erl_type: :boolean, erlang: :boolean]
  @aliases [r: :erl_type, e: :erlang]

  @impl Mix.Task
  def run(argv) when is_list(argv) do
    argv
    |> OptionParser.parse(switches: @switches, aliases: @aliases)
    |> run()
  end

  def run({_raw?, [], _rest}) do
    :ok
  end

  def run({raw?, [mod, func, arity], _rest}) do
    IO.puts("Preparing the PLT...")

    {:ok, plt} = Spectre.prepare_plt()

    mfa = {
      Module.concat(Elixir, String.to_atom(mod)),
      String.to_atom(func),
      String.to_integer(arity)
    }

    ["Looking up the spec for ", :yellow, inspect_mfa(mfa)]
    |> IO.ANSI.format()
    |> IO.puts()

    preamble = ["The spec for ", :yellow, inspect_mfa(mfa), :reset]

    result =
      case Spectre.lookup(plt, mfa, raw?) do
        :error ->
          [" could not be found."]

        spec ->
          [" is \n", :green, spec, :reset]
      end

    (preamble ++ result)
    |> IO.ANSI.format()
    |> IO.puts()
  end

  def run(_), do: usage()

  defp usage do
    IO.puts("""
    usage:
        mix spectre
    or
        mix spectre Module function arity

    for more, see `mix help spectre`
    """)

    System.halt(1)
  end

  defp inspect_mfa({mod, func, arity}) do
    module =
      mod
      |> Module.split()
      |> Enum.join(".")

    "#{module}.#{func}/#{arity}"
  end
end

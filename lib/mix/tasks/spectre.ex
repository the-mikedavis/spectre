defmodule Mix.Tasks.Spectre do
  use Mix.Task

  @version Mix.Project.config[:version]

  @shortdoc "Generate specs on functions"
  @moduledoc """
  # Spectre

  Version #{@version}

  Spectre creates `@spec`s on functions that don't have any. Spectre
  does not perform any static type checking, and will try to spec every
  function even the code will create run-time errors.

  ## Usage

  In any project's root directory

      mix spectre

  Recommended usage:

  1. Commit all your changes in your project directory.
  2. `mix spectre` in the project root.
  3. Use `git diff` to view the new specs.
  """
  @preferred_cli_env :test
  @recursive false

  @impl Mix.Task
  def run(_argv) do
    :ok
  end
end

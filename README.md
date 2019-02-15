# Spectre

Writing type specs is critical for code readability and can open wonderful
doors of static code analysis for Elixir. So why do so many projects lack full
specs? Well... it's kind of annoying when you need to go look up the
documentation on exactly what `:file.consult/1` returns every time you wanna
end a function with it.

Spectre provides a mix task that tells you what the
[`dialyzer`](http://erlang.org/doc/man/dialyzer.html) thinks your type specs
should be.

Spectre integrates closely with dialyxir. In fact, spectre uses dialyxir's
PLT or _persistent lookup table_ (a file used to store the dialyzer's analyses).

## Usage

You can use spectre to lookup the success typing on any function in the PLT.

    mix spectre <module> <function> <arity>

E.g.

    mix spectre File read 1

If you want to spec your entire project, you can do so with

    mix spectre

Recommended usage:

1. Commit all your changes in your project directory.
2. `mix spectre` in the project root.
3. Use `git diff` to view the new specs.
  - modify specs by hand for readability

## Installation

```elixir
def deps do
  [
    {:spectre, git: "git@github.com:the-mikedavis/spectre.git", runtime: false}
  ]
end
```

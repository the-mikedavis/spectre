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

> Spectre is still under repl based developement (the most active, reckless
> sort at that). Expect that spectre will only be usable once it's on Hex.pm.

## Installation

```elixir
def deps do
  [
    {:spectre, git: "git@github.com:the-mikedavis/spectre.git", runtime: false}
  ]
end
```

# Idicon

**    Idicon can be used to produce 5x5 user identifiable unique icons, also known as identicons.
    These are similar to the default icons used with github.
    Idicon supports 5x5 identicons in svg, png, or raw_bitmap, with custom padding.

    (String eg. User name) -> Idicon -> Image that is (mostly) unique to the user.
    Since the identicon can be produced repeatedly from the same input, it is not necessary
    to save the produced image anywhere. Instead, it can be rendered each time it is requested. **

## Installation

The package can be installed
by adding `identicon` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:idicon, "~> 0.1.1"}]
end
```

The documentation can be found at [https://hexdocs.pm/idicon](https://hexdocs.pm/identicon).


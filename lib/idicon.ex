defmodule Idicon do

  @moduledoc """
  Idicon can be used to produce 5x5 user identifiable unique icons, also known as identicons.
  These are similar to the default icons used with github.
  Idicon supports 5x5 identicons in svg, png, or raw_bitmap, with custom padding.

  (String eg. User name) -> Idicon -> Image that is (mostly) unique to the user.
  Since the identicon can be produced repeatedly from the same input, it is not necessary
  to save the produced image anywhere. Instead, it can be rendered each time it is requested.

  ## opts

  A Keyword List or Map with optional option values.

  By default:
  `opts = [type: :svg, color: :unique, size: 250, padding: 0]`

  keys:
  * `type:` - one of the atoms `:svg`, `:png`, or `:raw_bitmap`
  * `color:` - one of `:unique`, `:red`, `:blue`, `:green`, or `{r,g,b}` like `{110,250,45}`.
    A unique color is selected from the hash of the input, and will therefore change from identicon
    to identicon. Only change this if you are sure you want to override the color.
  * `size:` - a pixel size that defines both the height and width of the identicon
  * `padding:` - a pixel value that defines the padding between drawn squares of the identicon
  
  """

  @defaults %{type: :svg, color: :unique, padding: 0, size: 250, squares: 5 }
  @preset_colors %{red: {255,0,0}, green: {0,255,0}, blue: {0,0,255}}

  @doc """
  Create an identicon. The identicon can be sent to the client or saved.

  ## Examples

      svg_icon = Idicon.create("Elixir")
      red_png_icon_with_padding = Idicon.create("Elixir", type: :png, color: :red, padding: 5)
      large_turquoise_icon = Idicon.create("Elixir", [color: {64, 224, 208}, size: 1000])
      small_and_unique = Idicon.create("Elixir", %{color: :unique, size: 50})

      # Saving the Identicon using the helper function
      Idicon.create("Elixir")
        |> Identicon.save_image("./","Elixir.svg",)
      # Saving the image using the File module
      image = Idicon.create("Elixir")
      File.write("path", image)
  """

  def create(input, opts \\ []) do
    %{type: type, color: color, padding: padding, size: size, squares: squares} = Enum.into(opts, @defaults)
    size = round(size)
      input
        |> hash_input
        |> determine_color(color)
        |> set_grid(squares)
        |> filter_odd_squares
        |> build_pixel_map(size, squares)
        |> draw_image(type, padding, size)
  end
  
  @doc """
  Convenience function for saving the image.

  ## Examples

      iex> Idicon.create_and_save("Elixir","./../tmp/","elixir_icon.svg",[color: :red])

  """

  def create_and_save(input, path, name, opts) do
    create(input, opts)
      |> save_image(path, name)
  end

  @doc """
  By Default the path is the current directory, and name = input.type, eg. `ELIXER.svg`

  ## Examples

      iex> Idicon.create_and_save("Elixir")

  """

  def create_and_save(input, opts) when not is_bitstring opts do
    create_and_save(input, "", "#{input}.#{Enum.into(opts, @defaults).type}", opts)
  end

  @doc """
  ## Examples

      iex> Idicon.create_and_save("Elixir","./../tmp/")

  """

  def create_and_save(input, path \\ "", opts \\ []) do
    create_and_save(input, path, "#{input}.#{Enum.into(opts, @defaults).type}", opts)
  end

  def hash_input(input) do
    hex = :crypto.hash(:sha512, input)
      |> :binary.bin_to_list
    %Idicon.Image{hex: hex}
  end

  defp determine_color(image, {r,g,b}) do
    %Idicon.Image{image | color: {r,g,b}}
  end

  defp determine_color(%Idicon.Image{hex: [r, g, b | _tail]} = image, :unique) do
    %Idicon.Image{image | color: {r,g,b}}
  end

  defp determine_color(image, color) do
    IO.puts(color)
    %Idicon.Image{image | color: Map.fetch!(@preset_colors, color)}
  end

  defp set_grid(%Idicon.Image{hex: hex} = image, squares) do
    grid = 
      hex
        |> Enum.chunk(round(squares/2))
        |> Enum.map(&mirror_row(&1,squares))
        |> List.flatten
        |> Enum.with_index
    
    %Idicon.Image{image | grid: grid}
  end

  defp mirror_row(row, squares) do
    mirror_amount = round Float.floor(squares/2)
    additional = Enum.slice(row, 0..mirror_amount-1)
    # [first, second, third | _tail] = row
    # row ++ [third, second, first]
    row ++ Enum.reverse(additional)
  end

  defp filter_odd_squares(%Idicon.Image{grid: grid} = image) do
    grid = Enum.filter grid, fn({code, _index}) -> 
      rem(code, 2) == 0 
    end

    %Idicon.Image{image | grid: grid}
  end

  defp build_pixel_map(%Idicon.Image{grid: grid} = image, size, squares) do
    pixel_map = Enum.map grid, fn({_code, index}) ->
        square_size = round(size / squares)
        horizontal = rem(index, squares) * square_size
        vertical = div(index, squares) * square_size
        top_left = {horizontal, vertical}
        bottom_right = {horizontal + square_size, vertical + square_size}

        {top_left, bottom_right}
      end

    %Idicon.Image{image | pixel_map: pixel_map}
  end

  defp draw_image(%Idicon.Image{color: color, pixel_map: pixel_map}, :svg, padding, size) do
    {r,g,b}= color
    image = ~s[<svg version="1.1"
      baseProfile="full"
      width="#{size}" height="#{size}"
      xmlns="http://www.w3.org/2000/svg">]
    squares = Enum.map pixel_map, fn({start, stop}) ->
      {x0, y0} = start
      {x, y} = stop
      ~s[<rect x="#{x0 + padding}" y="#{y0 + padding}" width="#{x-x0-padding}" height="#{y-y0-padding}" fill="rgb(#{r},#{g},#{b})" />]
      end
    image <> Enum.join(squares) <> "</svg>"
  end

  defp draw_image(%Idicon.Image{color: color, pixel_map: pixel_map}, type, padding, size) do
    image = :egd.create(size, size)
    fill = :egd.color(color)
    Enum.each pixel_map, fn({start, stop}) ->
        start = {elem(start, 0) + padding, elem(start, 1 ) + padding}
        stop = {elem(stop, 0) - padding, elem(stop, 1) - padding}
        :egd.filledRectangle(image, start, stop, fill)
      end

    :egd.render(image, type)
  end

  @doc """
    Convenience method for saving the resulting image.
  """

  def save_image(image, path, name) do
    File.write(path <> name, image)
  end

end

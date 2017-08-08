defmodule Identicon do

  
  @moduledoc """
  Documentation for Identicon.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Identicon.create("Softhatch")

  """
  # opts = 
  # type: :svg / :png / :raw_bitmap
  # color: :unique, {r,g,b}
  # padding: padding
  # size: size
  # def create(input, opts \\ []) do
  #   main(input, opts)
  # end

  @defaults %{type: :svg, color: :unique, padding: 0, squares: 4, size: 250 }
  @preset_colors %{red: {255,0,0}, green: {0,255,0}, blue: {0,0,255}}
  @num_squares 5

  def create(input, opts \\ []) do
    %{type: type, color: color, padding: padding, size: size} = Enum.into(opts, @defaults)
    size = round(size)
      input
        |> hash_input
        |> determine_color(color)
        |> set_grid
        |> filter_odd_squares
        |> build_pixel_map(size)
        |> draw_image(type, padding, size)
  end
  
  def create_and_save(input, path, name, opts) do
    create(input, opts)
      |> save_image(path, name)
  end

  def create_and_save(input, opts) when not is_bitstring opts do
    create_and_save(input, "", "#{input}.#{Enum.into(opts, @defaults).type}", opts)
  end

  def create_and_save(input, path \\ "", opts \\ []) do
    create_and_save(input, path, "#{input}.#{Enum.into(opts, @defaults).type}", opts)
  end

  defp hash_input(input) do
    hex = :crypto.hash(:md5, input)
      |> :binary.bin_to_list
    %Identicon.Image{hex: hex}
  end

  defp determine_color(image, {r,g,b}) do
    %Identicon.Image{image | color: {r,g,b}}
  end

  defp determine_color(%Identicon.Image{hex: [r, g, b | _tail]} = image, :unique) do
    %Identicon.Image{image | color: {r,g,b}}
  end

  defp determine_color(image, color) do
    IO.puts(color)
    %Identicon.Image{image | color: Map.fetch!(@preset_colors, color)}
  end

  defp set_grid(%Identicon.Image{hex: hex} = image) do
    grid = 
      hex
        |> Enum.chunk(3)
        |> Enum.map(&mirror_row/1)
        |> List.flatten
        |> Enum.with_index
    
    %Identicon.Image{image | grid: grid}
  end

  defp mirror_row(row) do
    [first, second | _tail] = row
    row ++ [second, first]
  end

  defp filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    grid = Enum.filter grid, fn({code, _index}) -> 
      rem(code, 2) == 0 
    end

    %Identicon.Image{image | grid: grid}
  end

  defp build_pixel_map(%Identicon.Image{grid: grid} = image, size) do
    pixel_map = Enum.map grid, fn({_code, index}) ->
        square_size = round(size / @num_squares)
        horizontal = rem(index, @num_squares) * square_size
        vertical = div(index, @num_squares) * square_size
        top_left = {horizontal, vertical}
        bottom_right = {horizontal + square_size, vertical + square_size}

        {top_left, bottom_right}
      end

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  defp draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}, :svg, padding, size) do
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

  defp draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}, type, padding, size) do
    image = :egd.create(size, size)
    fill = :egd.color(color)
    Enum.each pixel_map, fn({start, stop}) ->
        start = {elem(start, 0) + padding, elem(start, 1 ) + padding}
        stop = {elem(stop, 0) - padding, elem(stop, 1) - padding}
        :egd.filledRectangle(image, start, stop, fill)
      end

    :egd.render(image, type)
  end

  defp save_image(image, path, name) do
    File.write(path <> name, image)
  end

end

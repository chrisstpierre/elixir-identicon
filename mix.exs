defmodule Idicon.Mixfile do
  use Mix.Project

  def project do
    [app: :idicon,
     version: "0.2.0",
     elixir: "~> 1.5",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     source_url: "https://github.com/Softhatch/elixir-identicon/",
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger, :crypto]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:egd, github: "erlang/egd"}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      licenses: ["MIT"],
      contributors: ["Softhatch"],
      maintainers: ["Softhatch"],
      links: %{"Github" => "https://github.com/softhatch/elixir-identicon"}
    ]
  end

  defp description do
    """
    Idicon can be used to produce 1x1 to 10x10 user identifiable unique icons, also known as identicons.
    These are similar to the default icons used with github.
    Idicon supports identicons in svg, png, or raw_bitmap, with custom padding.
    """
  end

end

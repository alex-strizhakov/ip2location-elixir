defmodule IP2Location.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ip2location,
      version: "0.1.1",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
    
      # package info
      package: [
        name: "ip2location_elixir",
        licenses: ["LGPLv3"],
        links: %{
          "GitHub" => "https://github.com/danielgracia/ip2location-elixir",
          "Docs" => "https://hexdocs.pm/ip2location-elixir"
        },
        maintainers: ["Daniel Gracia"]
      ],

      # doc info
      name: "IP2Location-Elixir",
      description: "Interface for accessing IP2Location Binary Format databases.",
      source_url: "https://github.com/danielgracia/ip2location-elixir",
      homepage_url: "https://github.com/danielgracia/ip2location-elixir",
      docs: [
        main: "IP2Location"
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    []
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:ex_doc, "~> 0.14", only: :dev, runtime: false}]
  end
end

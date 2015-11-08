defmodule Scrapex.Mixfile do
  use Mix.Project

  @version "0.3.0"

  def project do
    [app: :scrapex,
     version: @version,
     name: "Scrapex",
     description: """
     An open source and collaborative framework for extracting the data 
     you need from websites. In a fast, simple, yet extensible way.
     """,
     source_url: "https://bitbucket.org/inhuman/scrapex",
     homepage_url: "https://bitbucket.org/inhuman/scrapex/overview",
     elixir: "~> 1.1.1",
     escript: [main_module: Scrapex],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     package: package,
     docs: [source_ref: "v#{@version}",
            logo: "logo.png",
            extras: ["README.md"]]]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :httpoison]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:httpoison, "~> 0.7"},
      {:floki, "~> 0.7.0"},
      {:poison, "~> 1.4.0"},
      {:csv, "~> 1.2.1"},

      # Docs dependencies
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.10", only: :dev}
    ]
  end

  defp package do
    [contributors: ["Son Tran-Nguyen"],
     licenses: ["MIT"],
     links: %{bitbucket: "https://bitbucket.org/inhuman/scrapex"},
     files: ~w(lib priv test) ++
            ~w(CHANGELOG.md LICENSE mix.exs package.json README.md)]
  end
end
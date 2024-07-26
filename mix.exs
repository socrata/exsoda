defmodule Exsoda.Mixfile do
  use Mix.Project

  def project do
    [app: :exsoda,
     version: "4.1.35",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     package: package(),
     description: """
      A Socrata Soda2 API wrapper
     """
   ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Chris Duranti"],
      links: %{github: "https://github.com/rozap/exsoda"}
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :httpoison, :poison]]
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
      {:httpoison, "~> 1.0"},
      {:hackney, "~> 1.16.0"},
      {:poison, "~> 2.2.0"},
      {:nimble_csv, "~> 1.0"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:elixir_uuid, "~> 1.2"},
      {:plug, "~> 1.0"}
    ]
  end
end

defmodule Focus.Mixfile do
  use Mix.Project

  def project do
    [app: :focus,
     version: "0.3.5",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     consolidate_protocols: Mix.env != :test,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    [applications: [:logger]]
  end

  def description() do
    """
    A functional optics library. Create and compose lenses to view, set, and modify data inside arbitrarily nested maps, lists, and tuples.
    """
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:credo, "~> 0.5.3", only: [:dev, :test]},
      {:dialyxir, "~> 0.4.3", only: [:dev, :test]},
      {:quixir, "~> 0.9.1", only: [:test]}
    ]
  end

  defp package do
    [
      name: :focus,
      licenses: ["BSD2"],
      maintainers: ["Sylvie Poulsen"],
      links: %{
        "GitHub" => "https://github.com/smpoulsen/focus",
      }
    ]
  end
end

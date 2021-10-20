defmodule Focus.Mixfile do
  use Mix.Project

  def project do
    [
      app: :focus,
      version: "0.3.5",
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    extra_apps =
      case Mix.env() do
        :test -> [:stream_data]
        _ -> []
      end

    [applications: [:logger | extra_apps]]
  end

  def description() do
    """
    A functional optics library. Create and compose lenses to view, set, and modify data inside arbitrarily nested maps, lists, and tuples.
    """
  end

  defp deps do
    [
      {:ex_doc, ">= 0.25.0", only: :dev},
      {:credo, "~> 1.5.0", only: [:dev, :test]},
      {:dialyxir, "~> 1.1.0", only: [:dev, :test]},
      {:stream_data, "~> 0.5.0", only: [:test]}
    ]
  end

  defp package do
    [
      name: :focus,
      licenses: ["BSD2"],
      maintainers: ["Sylvie Poulsen"],
      links: %{
        "GitHub" => "https://github.com/smpoulsen/focus"
      }
    ]
  end
end

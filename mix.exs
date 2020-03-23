defmodule PowTotp.MixProject do
  use Mix.Project

  def project do
    [
      app: :pow_totp,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:pow, "~> 1.0.19"},
      {:pot, "~> 0.10.1"},
      {:qr_code, "~> 2.1.0"}
    ]
  end
end

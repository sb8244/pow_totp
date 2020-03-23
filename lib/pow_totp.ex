defmodule PowTotp do
  @moduledoc false
  use Pow.Extension.Base

  @impl true
  def ecto_schema?(), do: true

  @impl true
  def use_ecto_schema?(), do: true

  @impl true
  def phoenix_controller_callbacks?(), do: true

  @impl true
  def phoenix_router?(), do: true

  @impl true
  def phoenix_messages?(), do: true

  @impl true
  def phoenix_templates() do
    [
      {"setup", ~w(new edit)}
      {"session", ~w(new)}
    ]
  end
end

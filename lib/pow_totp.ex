defmodule PowTotp do
  @moduledoc false
  use Pow.Extension.Base

  @impl true
  def ecto_schema?(), do: true

  @impl true
  def use_ecto_schema?(), do: true

  @impl true
  def phoenix_controller_callbacks?(), do: false

  @impl true
  def phoenix_router?(), do: true
end

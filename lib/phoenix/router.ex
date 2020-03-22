defmodule PowTotp.Phoenix.Router do
  @moduledoc false
  use Pow.Extension.Phoenix.Router.Base

  alias Pow.Phoenix.Router

  defmacro routes(_config) do
    quote location: :keep do
      Router.pow_resources("/totp-setup", SetupController,
        only: [:new, :create, :edit],
        singleton: true
      )
    end
  end
end

defmodule PowTotp.Ecto.Context do
  alias Pow.{Ecto.Context}

  def update_totp(%user_mod{} = user, params, config) do
    params = PowTotp.Encryption.encrypt_totp_params(config, params)

    user
    |> user_mod.totp_changeset(params)
    |> Context.do_update(config)
  end
end

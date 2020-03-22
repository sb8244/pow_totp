defmodule PowTotp.Encryption do
  @salt "PowTotp.Encryption"

  def encrypt_totp_params(config, params = %{"totp_secret" => totp_secret}) do
    secret =
      Pow.Config.get(config, :totp_encryption_secret) ||
        Config.raise_error("totp_encryption_secret configuration option must be set to use totp")

    encrypted = Phoenix.Token.encrypt(secret, @salt, totp_secret, [])

    Map.put(params, "totp_secret", encrypted)
  end
end

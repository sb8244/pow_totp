defmodule PowTotp.Encryption do
  # TODO: This should use `Pow.Plug.MessageVerifier`, but it doesn't support encryption currently

  @salt "PowTotp.Encryption"

  def encrypt_totp_params(config, params = %{"totp_secret" => totp_secret}) do
    encrypt_secret =
      Pow.Config.get(config, :totp_encryption_secret) ||
        Pow.Config.raise_error(
          "totp_encryption_secret configuration option must be set to use totp"
        )

    encrypted = Phoenix.Token.encrypt(encrypt_secret, @salt, totp_secret, [])

    Map.put(params, "totp_secret", encrypted)
  end

  def decrypt_totp_secret(config, %{totp_secret: secret}) do
    encrypt_secret =
      Pow.Config.get(config, :totp_encryption_secret) ||
        Pow.Config.raise_error(
          "totp_encryption_secret configuration option must be set to use totp"
        )

    Phoenix.Token.decrypt(encrypt_secret, @salt, secret, max_age: :infinity)
  end
end

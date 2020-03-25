defmodule PowTotp.Plug do
  @moduledoc """
  Helper functions for Pow endpoints
  """

  require Logger

  alias PowTotp.Forms.CodeChangeset

  def generate_new_token(conn) do
    totp_secret = gen_totp_secret()
    changeset = CodeChangeset.changeset(%{"totp_secret" => totp_secret})
    svg = generate_svg(conn, %{"secret" => totp_secret})

    %{changeset: changeset, secret: totp_secret, svg: svg}
  end

  def try_new(totp_params = %{}) do
    totp_params
    |> CodeChangeset.changeset()
    |> CodeChangeset.apply_insert()
  end

  def persist_totp(conn, %{"secret" => totp_secret}) do
    config = Pow.Plug.fetch_config(conn)
    user = Pow.Plug.current_user(conn)

    PowTotp.Ecto.Context.update_totp(
      user,
      %{"totp_secret" => totp_secret, "totp_activated_at" => DateTime.utc_now()},
      config
    )
  end

  def verify_totp(conn, params, user) do
    config = Pow.Plug.fetch_config(conn)

    case PowTotp.Encryption.decrypt_totp_secret(config, user) do
      {:ok, secret} ->
        params
        |> Map.put("secret", secret)
        |> CodeChangeset.changeset()
        |> CodeChangeset.apply_insert()

      {:error, e} ->
        Logger.error("#{__MODULE__} decrypt_totp_secret failed error=#{inspect(e)}")
        {:error, :secret_failure}
    end
  end

  def generate_svg(conn = %Plug.Conn{}, %{"secret" => totp_secret}) do
    config = Pow.Plug.fetch_config(conn)
    user = Pow.Plug.current_user(conn)
    url = totp_url(user, totp_secret, totp_issuer(config))
    {:ok, qr} = QRCode.create(url)

    QRCode.Svg.to_base64(qr)
  end

  def requires_totp?(conn) do
    user = Pow.Plug.current_user(conn)
    user.totp_activated_at != nil and user.totp_secret != nil
  end

  def append_totp_verified_to_session_metadata(conn) do
    metadata =
      conn.private
      |> Map.get(:pow_session_metadata, [])
      |> Keyword.put(:totp_verified_at, timestamp())

    Plug.Conn.put_private(conn, :pow_session_metadata, metadata)
  end

  defp timestamp, do: :os.system_time(:millisecond)

  defp gen_totp_secret(), do: :crypto.strong_rand_bytes(30) |> Base.encode32()

  defp totp_issuer(config),
    do:
      Pow.Config.get(config, :totp_issuer) ||
        Pow.Config.raise_error("No totp_issuer configuration option provided. It's required to use PowTotp")

  defp totp_url(%{email: email}, secret, issuer) when is_bitstring(email),
    do: URI.encode("otpauth://totp/#{email}?secret=#{secret}&issuer=#{issuer}")

  defp totp_url(_, secret, issuer),
    do: URI.encode("otpauth://totp?secret=#{secret}&issuer=#{issuer}")
end

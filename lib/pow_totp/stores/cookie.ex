defmodule PowTotp.Stores.Cookie do
  alias Plug.Conn

  @cookie_key "totp"

  def put_user_identity(conn) do
    user = %user_mod{} = Pow.Plug.current_user(conn)
    user_id_field = user_mod.pow_user_id_field()
    user_identifier = Map.fetch!(user, user_id_field)

    client_store_put(conn, user_identifier)
  end

  def get_user_identity(conn) do
    client_store_get(conn)
  end

  def delete(conn) do
    client_store_delete(conn)
  end

  defp client_store_put(conn, identifier) do
    config = Pow.Plug.fetch_config(conn)
    signed_token = Pow.Plug.sign_token(conn, signing_salt(), identifier, config)

    conn
    |> Conn.fetch_cookies()
    |> Conn.put_resp_cookie(cookie_key(config), signed_token, cookie_opts(config))
  end

  defp client_store_get(conn) do
    config = Pow.Plug.fetch_config(conn)
    conn = Conn.fetch_cookies(conn)

    with token when is_binary(token) <- conn.req_cookies[cookie_key(config)],
         {:ok, identity} <- Pow.Plug.verify_token(conn, signing_salt(), token, config) do
      {identity, conn}
    else
      _any -> {nil, conn}
    end
  end

  defp client_store_delete(conn) do
    config = Pow.Plug.fetch_config(conn)

    conn
    |> Conn.fetch_cookies()
    |> Conn.delete_resp_cookie(cookie_key(config), cookie_opts(config))
  end

  defp signing_salt(), do: Atom.to_string(__MODULE__)

  defp cookie_key(config) do
    Pow.Config.get(config, :totp_cookie_key, default_cookie_key(config))
  end

  defp default_cookie_key(config) do
    Pow.Plug.prepend_with_namespace(config, @cookie_key)
  end

  defp cookie_opts(config) do
    config
    |> Pow.Config.get(:totp_cookie_opts, [])
    |> Keyword.put_new(:max_age, 60 * 10)
    |> Keyword.put_new(:path, "/")
  end
end

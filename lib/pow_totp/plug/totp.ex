defmodule PowTotp.Plug.Totp do
  @moduledoc """
  Enforces totp for users that are signed in, have totp activated, but haven't yet submitted a valid code. This
  is done by using the pow_session_metadata private. If `:totp_verified_at` is detected in this map, then the
  request is allowed. Otherwise, it will redirect to the specific totp endpoints.
  """

  import Plug.Conn

  def init(router: router),
    do: %{router: router}

  def call(conn, opts) do
    with %{totp_activated_at: time} when not is_nil(time) <- Pow.Plug.current_user(conn),
         nil <- extract_totp_verified_at(conn) do
      redirect_to_totp_session(conn, opts)
    else
      _ ->
        conn
    end
  end

  defp extract_totp_verified_at(conn) do
    get_in(conn.private, [:pow_session_metadata, :totp_verified_at])
  end

  defp redirect_to_totp_session(conn, %{router: router}) do
    config = Pow.Plug.fetch_config(conn)
    routes_backend = Pow.Config.get(config, :routes_backend, Pow.Phoenix.Routes)
    # Hack: The router isn't available yet, but life is so much easier with it. So require it passed in as plug opt
    routed_conn = put_private(conn, :phoenix_router, router)

    totp_session_path = routes_backend.path_for(routed_conn, PowTotp.Phoenix.SessionController, :new)
    totp_session_create_path = routes_backend.path_for(routed_conn, PowTotp.Phoenix.SessionController, :create)
    new_session_path = routes_backend.path_for(routed_conn, Pow.Phoenix.SessionController, :new)

    if conn.request_path in [totp_session_path, totp_session_create_path] do
      allow_request_to_proceed(conn)
    else
      if conn.request_path == new_session_path do
        clear_pow_session(conn)
      else
        redirect_to_totp_flow(conn, totp_session_path)
      end
    end
  end

  defp allow_request_to_proceed(conn), do: conn

  defp clear_pow_session(conn), do: Pow.Plug.delete(conn)

  defp redirect_to_totp_flow(conn, path) do
    conn
    |> Phoenix.Controller.redirect(to: path)
    |> halt()
  end
end

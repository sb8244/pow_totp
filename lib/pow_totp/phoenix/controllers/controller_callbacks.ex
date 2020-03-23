defmodule PowTotp.Phoenix.ControllerCallbacks do
  use Pow.Extension.Phoenix.ControllerCallbacks.Base

  alias PowTotp.Plug

  def before_respond(Pow.Phoenix.SessionController, :create, {:ok, conn}, _config) do
    maybe_require_totp(conn, {:ok, conn})
  end

  def before_respond(
        PowAssent.Phoenix.AuthorizationController,
        :callback,
        response = {:ok, %{private: %{pow_assent_callback_state: {:ok, :create_user}}}},
        _config
      ) do
    response
  end

  def before_respond(PowAssent.Phoenix.AuthorizationController, :callback, response = {:ok, conn}, _config) do
    maybe_require_totp(conn, response)
  end

  defp maybe_require_totp(conn, success_response) do
    case Plug.requires_totp?(conn) do
      true ->
        conn =
          conn
            |> PowTotp.Stores.Cookie.put_user_identity()
            |> Pow.Plug.delete()
            |> redirect_to_session_totp()

        {:halt, conn}

      false -> success_response
    end
  end

  defp redirect_to_session_totp(conn) do
    totp_session_path = routes(conn).path_for(conn, PowTotp.Phoenix.SessionController, :new)
    Phoenix.Controller.redirect(conn, to: totp_session_path)
  end
end

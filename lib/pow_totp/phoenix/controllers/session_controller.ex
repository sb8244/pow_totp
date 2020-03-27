defmodule PowTotp.Phoenix.SessionController do
  use Pow.Extension.Phoenix.Controller.Base

  plug(:require_authenticated)
  plug(:assign_create_path when action in [:new, :create])

  def process_new(conn, _params) do
    case Pow.Plug.current_user(conn) do
      %{totp_activated_at: time} when not is_nil(time) ->
        changeset = PowTotp.Forms.CodeChangeset.changeset(%{})
        {:ok, changeset, conn}

      _ ->
        {:error, :no_totp, conn}
    end
  end

  def respond_new({:ok, changeset, conn}) do
    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def respond_new({:error, :no_totp, conn}) do
    no_totp(conn)
  end

  def process_create(conn, %{"totp" => params}) do
    with {:user, user} when not is_nil(user) <- {:user, Pow.Plug.current_user(conn)},
         {:verify, {:ok, _changeset}} <- {:verify, PowTotp.Plug.verify_totp(conn, params, user)},
         conn <- PowTotp.Plug.append_totp_verified_to_session_metadata(conn),
         conn <- PowTotp.Plug.create_user(conn, user) do
      {:ok, user, conn}
    else
      {:cookie, {nil, _}} ->
        {:error, :no_totp, conn}

      {:user, nil} ->
        {:error, :no_user, conn}

      {:verify, {:error, :secret_failure}} ->
        {:error, :no_totp, conn}

      {:verify, {:error, changeset}} ->
        {:error, {:invalid, changeset}, conn}
    end
  end

  def respond_create({:ok, _user, conn}) do
    conn
    |> redirect(to: routes(conn).after_sign_in_path(conn))
  end

  def respond_create({:error, {:invalid, changeset}, conn}) do
    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def respond_create({:error, :no_totp, conn}) do
    no_totp(conn)
  end

  def respond_create({:error, :no_user, conn}) do
    conn
    |> put_flash(:error, extension_messages(conn).request_error(conn))
    |> redirect(to: routes(conn).session_path(conn, :new))
  end

  defp assign_create_path(conn, _opts) do
    path = routes(conn).path_for(conn, __MODULE__, :create)
    assign(conn, :action, path)
  end

  defp no_totp(conn) do
    conn
    |> put_flash(:error, extension_messages(conn).not_setup_error(conn))
    |> redirect(to: routes(conn).session_path(conn, :new))
  end
end

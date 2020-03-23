defmodule PowTotp.Phoenix.SessionController do
  use Pow.Extension.Phoenix.Controller.Base

  plug(:require_not_authenticated)
  plug(:assign_create_path when action in [:new, :create])

  def process_new(conn, _params) do
    case PowTotp.Stores.Cookie.get_user_identity(conn) do
      {nil, conn} ->
        {:error, :no_totp, conn}

      {_, conn} ->
        changeset = PowTotp.Forms.CodeChangeset.changeset(%{})
        {:ok, changeset, conn}
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
    with {:cookie, {identity, conn}} when not is_nil(identity) <- {:cookie, PowTotp.Stores.Cookie.get_user_identity(conn)},
         {:user, user} when not is_nil(user) <- {:user, fetch_user(identity, conn)},
         {:verify, {:ok, _changeset}} <- {:verify, PowTotp.Plug.verify_totp(conn, params, user)},
         conn <- Pow.Plug.create(conn, user) do
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
    |> PowTotp.Stores.Cookie.delete()
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
    |> PowTotp.Stores.Cookie.delete()
    |> put_flash(:error, extension_messages(conn).request_error(conn))
    |> redirect(to: routes(conn).session_path(conn, :new))
  end

  defp assign_create_path(conn, _opts) do
    path = routes(conn).path_for(conn, __MODULE__, :create)
    assign(conn, :action, path)
  end

  defp fetch_user(identity, conn) do
    config = Pow.Plug.fetch_config(conn)
    user_mod = Pow.Config.user!(config)
    user_id_field = user_mod.pow_user_id_field()

    Pow.Ecto.Context.get_by(%{user_id_field => identity}, config)
  end

  defp no_totp(conn) do
    conn
    |> PowTotp.Stores.Cookie.delete()
    |> put_flash(:error, extension_messages(conn).not_setup_error(conn))
    |> redirect(to: routes(conn).session_path(conn, :new))
  end
end

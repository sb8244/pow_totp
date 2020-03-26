defmodule PowTotp.Phoenix.SetupController do
  use Pow.Extension.Phoenix.Controller.Base
  require Logger
  alias PowTotp.Plug

  plug(:require_authenticated)
  plug(:assign_create_path when action in [:new, :create])

  def process_new(conn, _params) do
    case Pow.Plug.current_user(conn) do
      %{totp_activated_at: time} when not is_nil(time) ->
        {:error, :already_setup, conn}

      _ ->
        {:ok, Plug.generate_new_token(conn), conn}
    end
  end

  def respond_new({:ok, %{secret: secret, svg: svg, changeset: changeset}, conn}) do
    conn
    |> assign(:secret, secret)
    |> assign(:svg, svg)
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def respond_new({:error, :already_setup, conn}) do
    totp_activated_redirect(conn)
  end

  def process_create(conn, %{"totp" => params}) do
    case Plug.try_new(params) do
      {:ok, _changeset} ->
        case Plug.persist_totp(conn, params) do
          {:ok, user} ->
            {:ok, {:redirect, user}, conn}

          {:error, err} ->
            Logger.error("#{__MODULE__} persist_totp failed error=#{inspect(err)}")
            {:error, :persistence, conn}
        end

      {:error, changeset} ->
        {:error, %{params: params, changeset: changeset}, conn}
    end
  end

  def respond_create({:ok, {:redirect, user}, conn}) do
    conn
    |> Plug.append_totp_verified_to_session_metadata()
    |> Pow.Plug.create(user)
    |> totp_activated_redirect()
  end

  def respond_create({:error, %{params: params, changeset: changeset}, conn}) do
    svg = Plug.generate_svg(conn, params)

    conn
    |> assign(:secret, params["secret"])
    |> assign(:svg, svg)
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def respond_create({:error, :persistence, conn}) do
    conn
    |> put_flash(:error, extension_messages(conn).request_error(conn))
    |> redirect(to: routes(conn).session_path(conn, :new))
  end

  def process_edit(conn, _params) do
    user = Pow.Plug.current_user(conn)

    case user do
      %{totp_activated_at: nil} ->
        {:error, :not_setup, conn}

      _ ->
        {:ok, :response, conn}
    end
  end

  def respond_edit({:ok, :response, conn}) do
    conn
    |> render("edit.html")
  end

  def respond_edit({:error, :not_setup, conn}) do
    conn
    |> put_flash(:error, extension_messages(conn).not_setup_error(conn))
    |> redirect(to: routes(conn).path_for(conn, __MODULE__, :new))
  end

  def process_delete(conn, _params) do
    case Plug.disable_totp(conn) do
      {:ok, _user} ->
        {:ok, :redirect, conn}
    end
  end

  def respond_delete({:ok, :redirect, conn}) do
    totp_activated_redirect(conn)
  end

  defp assign_create_path(conn, _opts) do
    path = routes(conn).path_for(conn, __MODULE__, :create)
    assign(conn, :action, path)
  end

  defp totp_activated_redirect(conn) do
    conn
    |> redirect(to: routes(conn).path_for(conn, __MODULE__, :edit))
  end
end

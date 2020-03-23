defmodule PowTotp.Phoenix.SetupController do
  use Pow.Extension.Phoenix.Controller.Base

  plug(:require_authenticated)
  plug(:assign_create_path when action in [:new, :create])

  alias PowTotp.Plug

  def process_new(conn, _params) do
    {:ok, Plug.generate_new_token(conn), conn}
  end

  def respond_new({:ok, %{secret: secret, svg: svg, changeset: changeset}, conn}) do
    IO.inspect(:pot.totp(secret))

    conn
    |> assign(:secret, secret)
    |> assign(:svg, svg)
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def process_create(conn, %{"totp" => params}) do
    case Plug.try_new(params) do
      {:ok, _changeset} ->
        case Plug.persist_totp(conn, params) do
          {:ok, _user} ->
            {:ok, :redirect, conn}

          {:error, err} ->
            # TODO: Handle error here
            throw(err)
        end

      {:error, changeset} ->
        {:error, %{params: params, changeset: changeset}, conn}
    end
  end

  def respond_create({:error, %{params: params, changeset: changeset}, conn}) do
    svg = Plug.generate_svg(conn, params)

    conn
    |> assign(:secret, params["secret"])
    |> assign(:svg, svg)
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def respond_create({:ok, :redirect, conn}) do
    totp_activated_redirect(conn)
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
    |> redirect(to: routes(conn).path_for(conn, __MODULE__, :new))
  end

  # TODO: Allow user to delete TOTP

  defp assign_create_path(conn, _opts) do
    path = routes(conn).path_for(conn, __MODULE__, :create)
    assign(conn, :action, path)
  end

  defp totp_activated_redirect(conn) do
    conn
    |> redirect(to: routes(conn).path_for(conn, __MODULE__, :edit))
  end
end

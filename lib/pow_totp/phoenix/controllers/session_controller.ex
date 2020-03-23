defmodule PowTotp.Phoenix.SessionController do
  use Pow.Extension.Phoenix.Controller.Base

  plug(:require_not_authenticated)
  plug(:assign_create_path when action in [:new, :create])

  def process_new(conn, _params) do
    case PowTotp.Stores.Cookie.get_user_identity(conn) do
      {nil, conn} ->
        {:error, :no_totp, conn}

      {_, conn} ->
        {:ok, :response, conn}
    end
  end

  def respond_new({:ok, :response, conn}) do
    conn
    |> render("new.html")
  end

  def respond_new({:error, :no_totp, conn}) do
    # TODO: Include a flash here
    conn
    |> redirect(to: routes(conn).session_path(conn, :new))
  end

  defp assign_create_path(conn, _opts) do
    path = routes(conn).path_for(conn, __MODULE__, :create)
    assign(conn, :action, path)
  end
end

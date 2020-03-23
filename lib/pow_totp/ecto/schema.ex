defmodule PowTotp.Ecto.Schema do
  use Pow.Extension.Ecto.Schema.Base
  import Ecto.Changeset

  @doc false
  @impl true
  def attrs(_config) do
    [
      {:totp_activated_at, :utc_datetime},
      {:totp_secret, :string}
    ]
  end

  @doc false
  @impl true
  def assocs(_config) do
    []
  end

  @doc false
  @impl true
  def indexes(_config) do
    []
  end

  @doc false
  @impl true
  defmacro __using__(_config) do
    quote do
      def totp_changeset(changeset, attrs), do: pow_totp_changeset(changeset, attrs)

      defdelegate pow_totp_changeset(changeset, attrs),
        to: unquote(__MODULE__),
        as: :totp_changeset

      defoverridable totp_changeset: 2
    end
  end

  def totp_changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> cast(attrs, [:totp_activated_at, :totp_secret])
  end
end

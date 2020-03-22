defmodule PowTotp.CodeChangeset do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:code)
  end

  def changeset(params = %{}) do
    %__MODULE__{}
    |> cast(params, [:code])
    |> validate_change(:code, fn :code, _ ->
      if verify_totp(params) do
        []
      else
        [code: "is invalid"]
      end
    end)
  end

  def apply_insert(changeset) do
    apply_action(changeset, :insert)
  end

  defp verify_totp(%{"code" => test_code, "secret" => secret}) do
    PowTotp.Verifier.verify(test_code, secret)
  end

  defp verify_totp(_), do: false
end

defmodule PowTotp.Verifier do
  def verify(code, secret) do
    code
    |> String.replace(" ", "")
    |> :pot.valid_totp(secret, window: 2, addwindow: 1)
  end
end

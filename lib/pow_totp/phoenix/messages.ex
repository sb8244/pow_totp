defmodule PowTotp.Phoenix.Messages do
  @moduledoc """
  Module that handles messages for PowTotp.
  See `Pow.Extension.Phoenix.Messages` for more.
  """

  @doc """
  Flash message to show when an unexpected error occurs while processing 2FA.
  """
  def request_error(_conn), do: "An error occurred processing your 2FA request."

  @doc """
  Flash message to show when user tries to access totp but doesn't have 2FA setup.
  """
  def not_setup_error(_conn), do: "2FA is disabled."

  @doc """
  Flash message to show when a user deactives TOTP
  """
  def totp_disabled(_conn), do: "2FA has been disabled."

  @doc """
  Flash message to show when TOTP is setup
  """
  def totp_setup(_conn), do: "2FA is now enabled."
end

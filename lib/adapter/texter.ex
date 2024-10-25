defmodule Texto.Texter do

  @moduledoc """
  Texter module for sending SMS messages.
  """

  @doc """
  Send an SMS message.

  ## Parameters
  - adapter_data: Adapter struct.
  - message: the SMS message to send.

  ## Returns
  - :ok if the message was sent successfully.
  - :error if the message was not sent cause service rejected it.
  ## Raises
  - `RuntimeError` if sending the message fails.
  """
  @callback send_sms!(self :: struct(), message :: Texto.SmsMessage.t()) :: {:ok, String.t()} | {:error, any()}

end

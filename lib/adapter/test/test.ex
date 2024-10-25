defmodule Texto.Adapter.Test do
  @behaviour Texto.Texter

  defstruct []
  @type t :: %__MODULE__{}

  require Logger

  @impl true
  @spec send_sms!(t(), Texto.SmsMessage.t()) :: {:ok, map()} | {:error, any()}
  def send_sms!(%__MODULE__{} = _self, %Texto.SmsMessage{} = message) do
    # Implement the function logic here
    Logger.info("SMS sent to #{message.phone} with message: #{message.body}")
    {:ok, "SMS sent to #{message.phone} with message: #{message.body}"}
  end
end

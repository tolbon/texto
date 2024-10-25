defmodule Texto do
  alias Texto.SmsMessage
  alias Texto.Adapter
  require Logger

  @spec createAdapterWithDSN!(String.t()) :: Texto.Texter
  def createAdapterWithDSN!(dsn) do
    uri = URI.parse(dsn)
    createAdapterWithURI(uri)
  end

  def createAdapterWithURI(%URI{scheme: "orange-business"} = uri) do
    Adapter.OrangeBusiness.new(uri)
  end

  def createAdapterWithURI(%URI{scheme: "test"} = uri) do
    Logger.info("Par ici #{uri}")
    Adapter.Test.__struct__([])
  end

  def send_sms!(%Adapter.OrangeBusiness{} = struct, %SmsMessage{} = message) do
    Adapter.OrangeBusiness.send_sms!(struct, message)
  end

  def send_sms!(%Adapter.Test{} = struct, %SmsMessage{} = message) do
    Adapter.Test.send_sms!(struct, message)
  end
end

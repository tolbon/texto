defmodule TextoTest do
  use ExUnit.Case
  doctest Texto

  test "Test" do
    adapter = Texto.createAdapterWithDSN!("test://")
    sms = Texto.SmsMessage.new("+3327557976", "Hello, world!")
    Texto.send_sms!(adapter, sms)

    adapter |> Texto.send_sms!(sms)
  end

end

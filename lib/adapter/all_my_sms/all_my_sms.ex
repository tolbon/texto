defmodule Texto.Adapter.AllMySms do
  @moduledoc """
  SMS service using AllMySMS.
  https://doc.allmysms.com/api/fr/
  """
  alias Texto.SmsMessage
  @behaviour Texto.Texter

  @default_host "https://api.allmysms.com"
  @url_sms "/sms/send/"

  defstruct [login: "", api_key: ""]
  @type t :: %__MODULE__{
    login: String.t(),
    api_key: String.t()
  }

  @spec new(String.t(), String.t()) :: t()
  def new(login, api_key) when is_bitstring(login) and is_bitstring(api_key) do
    %__MODULE__{login: login, api_key: api_key}
  end

  @spec new(URI.t()) :: t()
  def new(%URI{} = dsn) do
    [login, api_key] = String.split(dsn.userinfo, ":", parts: 2)
    new(login, api_key)
  end

  def send_sms!(%__MODULE__{} = self, %SmsMessage{} = message) do

    merged_options = Keyword.merge(message.options, [from: message.from, to: message.to, text: message.body])
    response = Req.post!(@default_host <> @url_sms, [auth: {:basic, self.login <> ":" <> self.api_key}, json: merged_options])
    case response.status do
      201 -> {:ok, response.body}
      _ -> {:error, "Failed to send SMS with status: #{(hd response.body)["message"]}"}
    end

    if (not response.body["smsId"]) do
      {:error, "Failed to send SMS with status: #{response.body["description"]}"}
    end

    {:ok, response.body["smsId"]}
  end
end

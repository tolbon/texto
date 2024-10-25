defmodule Texto.SmsMessage do
  defstruct [:phone, :body, from: "", options: %{}]
  @type t :: %__MODULE__{
    phone: String.t(),
    body: String.t(),
    from: String.t(),
    options: map()
  }

  @spec new(any(), any(), any(), any()) :: Texto.SmsMessage.t()
  def new(phone, body, from \\ "", options \\ %{}) do
    %__MODULE__{phone: phone, body: body, from: from, options: options}
  end
end

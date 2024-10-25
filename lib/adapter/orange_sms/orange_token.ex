defmodule Texto.Adapter.OrangeSmsToken do

  defstruct token: "", timestamp_token_expiration: 0

  @type t :: %__MODULE__{
    token: String.t(),
    timestamp_token_expiration: non_neg_integer()
  }
end

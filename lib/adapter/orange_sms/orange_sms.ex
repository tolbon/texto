defmodule Texto.Adapter.OrangeSMS do
  @moduledoc """
  SMS service using Orange Business API v1.2.
  https://contact-everyone.orange-business.com/api/docs/guides/#contact-everyone
  """
  alias Texto.Adapter.OrangeBusinessToken
  @behaviour Texto.Texter
  use Agent

  @default_host "https://contact-everyone.orange-business.com/api/v1.2"
  @url_token "/oauth/token"
  @url_groups "/groups";
  @url_diffusion "/groups/:id-group/diffusion-requests"

  @url_auth_token URI.encode(@default_host <> @url_token)
  @url_get_groups URI.encode(@default_host <> @url_groups)

  defstruct username: "", password: "", id_group: ""

  @type t :: %__MODULE__{
    username: String.t(),
    password: String.t(),
    id_group: String.t()
  }

  @spec new(String.t(), String.t(), String.t()) :: t()
  def new(username, password, id_group) when is_bitstring(username) and is_bitstring(password) and is_bitstring(id_group) do
    start_link(String.to_atom(id_group))
    %__MODULE__{username: username, password: password, id_group: id_group}
  end

  @spec new(URI.t()) :: t()
  def new(%URI{} = dsn) do
    [username, password] = String.split(dsn.userinfo, ":", parts: 2)
    id_group = URI.decode_query(dsn.query)["id_group"]
    group_name = URI.decode_query(dsn.query)["group_name"]

    if (group_name == false && id_group == false) do
      raise RuntimeError, message: "Please provide a group_name or id_group"
    end
    id_group = case id_group do
      true -> id_group
      false -> get_id_group_by_name!(username, password, group_name)
    end
    new(username, password, id_group)
  end

  @spec start_link(atom()) :: {:error, any()} | {:ok, pid()}
  def start_link(name) do
    Agent.start_link(fn -> %OrangeBusinessToken{token: "", timestamp_token_expiration: 0} end, name: name)
  end


  @impl true
  @spec send_sms!(t(), Texto.SmsMessage.t()) :: {:ok, map()} | {:error, any()}
  def send_sms!(%__MODULE__{} = self, %Texto.SmsMessage{} = message) do
    id_group = self.id_group
    atom_id_group = String.to_atom(id_group)
    orange_token = Agent.get(atom_id_group, & &1)

    orange_token = if not token_is_valid?(orange_token) do
      orange_auth_info = authenticate!(self.username, self.password)
      Agent.update(atom_id_group, fn _ -> orange_auth_info end)

      orange_auth_info
    else
      orange_token
    end

    url = String.replace(@url_diffusion, ":id-group", id_group)
    headers = [{"Authorization", "Bearer #{orange_token.token}"}]
    response = Req.post!(URI.encode(@default_host <> url), [headers: headers, json: %{
      msisdns: [message.phone],
      smsParam: %{
        senderName: message.from,
        encoding: "GSM7",
        body: message.body,
      }
    }])

    case response.status do
      201 -> {:ok, response.body}
      _ -> {:error, "Failed to send SMS with status: #{(hd response.body)["message"]}"}
    end
  end

  @spec get_id_group_by_name!(String.t(), String.t(), String.t()):: String.t()
  defp get_id_group_by_name!(username, password, group_name) do
    orange_token = authenticate!(username, password)

    headers = [{"Authorization", "Bearer #{orange_token.token}"}]
    response = Req.get!(@url_get_groups, [headers: headers])

    case response.status do
      200 ->
        body_response = response.body
        group = Enum.find(body_response, fn group -> group["name"] == group_name end)
        if group do
          group["id"]
        else
          raise RuntimeError, message: "Group with name #{group_name} not found"
        end
      _ ->
        raise RuntimeError, message: "Authentication failed with status: #{response.body}"
    end
  end

  @spec authenticate!(String.t(), String.t()) :: OrangeBusinessToken.t()
  defp authenticate!(username, password) do
    response = Req.post!(@url_auth_token, [
      form: [
        username: username,
        password: password
      ]
    ]);

    case response.status do
      200 ->
        body_response = response.body
        decoded_body = %{
          access_token: body_response["access_token"],
          token_type: body_response["token_type"],
          scope: body_response["scope"],
          ttl: body_response["ttl"]
        }
        timestamp_token_expiration = DateTime.utc_now()
        |> DateTime.to_unix(:millisecond)
        |> Kernel.+(decoded_body.ttl * 1000)

        %OrangeBusinessToken{token: decoded_body.access_token, timestamp_token_expiration: timestamp_token_expiration}
      _ ->
        raise RuntimeError, message: "Authentication failed with status: #{response.status}"
    end
  end

  defp token_is_valid?(%OrangeBusinessToken{token: token, timestamp_token_expiration: timestamp_token_expiration}) do
    if token == "" or DateTime.utc_now() |> DateTime.to_unix(:millisecond) > timestamp_token_expiration do
      false
    else
      true
    end
  end
end

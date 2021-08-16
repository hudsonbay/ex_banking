defmodule ExBanking do
  use GenServer
  alias ExBanking.Validations

  # Client

  def start_link do
    GenServer.start_link(__MODULE__, [:ex_banking], name: __MODULE__)
  end

  @doc """
  - Function creates new user in the system
  - New user has zero balance of any currency
  """
  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    start_link()

    if Validations.user_valid?(user) do
      {:error, :wrong_arguments}
    else
      GenServer.call(__MODULE__, {:create_user, user})
    end
  end

  # Server (callbacks)

  def init(_) do
    {:ok, []}
  end

  def handle_call({:create_user, user}, _from, user_list) do
    case Validations.find_user(user_list, user) do
      nil ->
        updated_list = [Map.new([{user, []}]) | user_list]
        {:reply, :ok, updated_list}

      _ ->
        {:reply, {:error, :user_already_exists}, user_list}
    end
  end
end

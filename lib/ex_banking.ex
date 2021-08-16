defmodule ExBanking do
  use GenServer

  # Client

  def start_link do
    GenServer.start_link(__MODULE__, [:ex_banking], name: __MODULE__)
  end

  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    start_link()

    GenServer.call(__MODULE__, {:create_user, user})
  end

  # Server (callbacks)

  def init(_) do
    {:ok, []}
  end

  def handle_call({:create_user, user}, _from, user_list) do
    {:reply, :ok, user_list}
  end
end

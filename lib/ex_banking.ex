defmodule ExBanking do
  use GenServer

  alias ExBanking.BankingUtils
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

  @doc """
  - Increases user’s balance in given currency by amount value
  - Returns new_balance of the user in given format
  """
  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency) do
    start_link()

    GenServer.call(__MODULE__, {:deposit, user, amount, currency})
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

  def handle_call({:deposit, user, amount, currency}, _from, user_list) do
    case Validations.find_user(user_list, user) do
      nil ->
        {:reply, {:error, :user_does_not_exist}, user_list}

      found_user ->
        if Validations.valid_amount?(amount, currency) do
          {new_amount, new_bank_state} =
            BankingUtils.make_deposit(user, found_user, amount, currency, user_list)

          {:reply, {:ok, new_amount}, new_bank_state}
        else
          {:reply, {:error, :wrong_arguments}, user_list}
        end
    end
  end
end

defmodule ExBanking do
  @moduledoc """
  Main module appication
  """
  use GenServer

  alias ExBanking.BankingUtils
  alias ExBanking.Validations

  # Client

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [:ex_banking], name: __MODULE__)
  end

  @doc """
  - Function creates new user in the system
  - New user has zero balance of any currency
  """
  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    if Validations.user_valid?(user) do
      {:error, :wrong_arguments}
    else
      ExBanking.UserSupervisor.supervise_user(user)
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
    case ExBanking.UserSupervisor.supervise_user(user) do
      :ok ->
        GenServer.call(__MODULE__, {:deposit, user, amount, currency})

      :error ->
        GenServer.call(__MODULE__, {:error, :too_many_requests_to_user})
    end
  end

  @doc """
  - Decreases user’s balance in given currency by amount value
  - Returns new_balance of the user in given format
  """
  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency) do
    case ExBanking.UserSupervisor.supervise_user(user) do
      :ok ->
        GenServer.call(__MODULE__, {:withdraw, user, amount, currency})

      :error ->
        GenServer.call(__MODULE__, {:error, :too_many_requests_to_user})
    end
  end

  @doc """
  Returns balance of the user for the given currency
  """
  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) do
    case ExBanking.UserSupervisor.supervise_user(user) do
      :ok ->
        GenServer.call(__MODULE__, {:get_balance, user, currency})

      :error ->
        GenServer.call(__MODULE__, {:error, :too_many_requests_to_user})
    end
  end

  @doc """
  - Decreases from_user’s balance in given currency by amount value
  - Increases to_user’s balance in given currency by amount value
  - Returns balance of from_user and to_user in given format
  """
  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}
  def send(from_user, to_user, amount, currency) do
    case ExBanking.UserSupervisor.supervise_user(from_user) do
      :ok ->
        GenServer.call(__MODULE__, {:send, from_user, to_user, amount, currency})

      :error ->
        GenServer.call(__MODULE__, {:error, :too_many_requests_to_user})
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

  def handle_call({:withdraw, user, amount, currency}, _from, user_list) do
    if Validations.valid_amount?(amount, currency) do
      case Validations.find_user(user_list, user) do
        nil ->
          {:reply, {:error, :user_does_not_exist}, user_list}

        found_user ->
          case BankingUtils.make_withdraw(user, found_user, amount, currency, user_list) do
            {:ok, new_amount, new_bank_state} ->
              {:reply, {:ok, new_amount}, new_bank_state}

            {:error, :not_enough_money} ->
              {:reply, {:error, :not_enough_money}, user_list}
          end
      end
    else
      {:reply, {:error, :wrong_arguments}, user_list}
    end
  end

  def handle_call({:get_balance, user, currency}, _from, user_list) do
    if Validations.valid_currency?(currency) do
      case Validations.find_user(user_list, user) do
        nil ->
          {:reply, {:error, :user_does_not_exist}, user_list}

        found_user ->
          BankingUtils.get_balance(user, found_user, currency, user_list)
      end
    else
      {:reply, {:error, :wrong_arguments}, user_list}
    end
  end

  def handle_call({:send, from_user, to_user, amount, currency}, _from, user_list) do
    if Validations.valid_amount?(amount, currency) do
      case Validations.find_user(user_list, from_user) do
        nil ->
          {:reply, {:error, :sender_does_not_exist}, user_list}

        found_user ->
          BankingUtils.attempt_sending(
            from_user,
            found_user,
            to_user,
            amount,
            currency,
            user_list
          )
      end
    else
      {:reply, {:error, :wrong_arguments}, user_list}
    end
  end

  def handle_call({:error, :too_many_requests_to_user}, _from, user_list) do
    {:reply, {:error, :too_many_requests_to_user}, user_list}
  end
end

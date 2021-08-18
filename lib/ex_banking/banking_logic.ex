defmodule ExBanking.BankingUtils do
  @moduledoc """
  Module to store all functions that deal with logic to make successful banking operations
  """

  alias ExBanking.Validations

  @doc """
  Deposits money into the given user account, based on it's currency.
  If the user doesn't have an account of that currency, it creates it automatically.
  """
  def make_deposit(user, found_user, amount, currency, user_list) do
    account = Validations.find_user_account_by_currency(user, found_user, currency)

    case account do
      nil ->
        new_bank_state =
          create_account_and_put_money_inside(user, found_user, amount, currency, user_list)

        {amount, new_bank_state}

      _ ->
        {:ok, new_amount, new_bank_state} =
          put_money(user, account, found_user, amount, user_list)

        {new_amount, new_bank_state}
    end
  end

  @doc """
  Decreases user’s balance in given currency by amount value as long as there's
  enough money to withdraw.
  Returns new_balance of the user in given format
  """
  def make_withdraw(user, found_user, amount, currency, user_list) do
    if Validations.enough_money_for_withdrawal?(user, found_user, amount, currency) do
      account = Validations.find_user_account_by_currency(user, found_user, currency)

      updated_account =
        account
        |> Map.get_and_update("amount", fn current_amount ->
          {current_amount,
           Decimal.sub(Validations.to_decimal(current_amount), Validations.to_decimal(amount))
           |> Decimal.round(2)
           |> Decimal.to_float()}
        end)
        |> elem(1)

      update_user_info(found_user, user, account, updated_account, user_list)
    else
      {:error, :not_enough_money}
    end
  end

  defp create_account_and_put_money_inside(user, found_user, amount, currency, user_list) do
    new_account =
      [
        Map.new([{"amount", amount}, {"currency", currency}])
        | found_user
          |> Map.get(user)
      ] -- [found_user]

    update_bank_state(user, new_account, found_user, user_list)
  end

  @doc """
  Updates the bank state
  """
  def update_bank_state(user, updated_user_info, found_user, user_list) do
    new_user = Map.new([{user, updated_user_info}])

    [new_user | user_list] -- [found_user]
  end

  defp put_money(user, account, found_user, amount, user_list) do
    updated_account =
      account
      |> Map.get_and_update("amount", fn current_amount ->
        {current_amount,
         Decimal.add(Validations.to_decimal(current_amount), Validations.to_decimal(amount))
         |> Decimal.round(2)
         |> Decimal.to_float()}
      end)
      |> elem(1)

    update_user_info(found_user, user, account, updated_account, user_list)
  end

  defp update_user_info(found_user, user, account, updated_account, user_list) do
    updated_user_info =
      found_user
      |> Map.get(user)

    new_bank_state =
      update_bank_state(
        user,
        [updated_account | updated_user_info] -- [account],
        found_user,
        user_list
      )

    {:ok, Map.get(updated_account, "amount"), new_bank_state}
  end

  def get_balance(user, found_user, currency, user_list) do
    account = Validations.find_user_account_by_currency(user, found_user, currency)

    case account do
      nil ->
        {:reply, {:error, :wrong_arguments}, user_list}

      _ ->
        {:reply, {:ok, account |> Map.get("amount")}, user_list}
    end
  end

  @doc """
  Makes all the neccesary validations before sending money from user X to Y.
  If all validations pass, then the transaction is handled
  """
  def attempt_sending(user, sender_user, to_user, amount_to_send, currency, user_list) do
    sender_account = Validations.find_user_account_by_currency(user, sender_user, currency)

    case sender_account do
      nil ->
        {:reply, {:error, :wrong_arguments}, user_list}

      _ ->
        if Map.get(sender_account, "amount") > amount_to_send do
          case Validations.find_user(user_list, to_user) do
            nil ->
              {:reply, {:error, :receiver_does_not_exist}, user_list}

            receiver ->
              complete_transaction(
                user,
                sender_user,
                to_user,
                receiver,
                amount_to_send,
                currency,
                user_list
              )
          end
        else
          {:reply, {:error, :not_enough_money}, user_list}
        end
    end
  end

  defp complete_transaction(
        user,
        sender_user,
        to_user,
        receiver,
        amount_to_send,
        currency,
        user_list
      ) do
    {new_amount_receiver, _} =
      make_deposit(to_user, receiver, amount_to_send, currency, user_list)

    {:ok, new_amount_sender, new_bank_state} =
      make_withdraw(user, sender_user, amount_to_send, currency, user_list)

    {:reply, {:ok, new_amount_sender, new_amount_receiver}, new_bank_state}
  end
end

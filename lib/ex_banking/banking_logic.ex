defmodule ExBanking.BankingUtils do
  @moduledoc """
  Module to store all functions that deal with logic to make successful banking operations
  """

  alias ExBanking.Validations

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

  def make_withdraw(user, found_user, amount, currency, user_list) do
    if Validations.enough_money_for_withdrawal?(user, found_user, amount, currency) do
      account = Validations.find_user_account_by_currency(user, found_user, currency)

      updated_account =
        account
        |> Map.get_and_update("amount", fn current_amount ->
          {current_amount, current_amount - amount}
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

  def update_bank_state(user, updated_user_info, found_user, user_list) do
    new_user = Map.new([{user, updated_user_info}])

    [new_user | user_list] -- [found_user]
  end

  defp put_money(user, account, found_user, amount, user_list) do
    updated_account =
      account
      |> Map.get_and_update("amount", fn current_amount ->
        {current_amount, current_amount + amount}
      end)
      |> elem(1)

    update_user_info(found_user, user, account, updated_account, user_list)
  end

  def update_user_info(found_user, user, account, updated_account, user_list) do
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
end

defmodule ExBanking.Validations do
  @moduledoc """
  Module to store all validations funcions needed to maintain integrity
  """

  def user_valid?(user) do
    !is_binary(user) or String.length(user) == 0
  end

  def find_user(user_list, user) do
    user_list
    |> Enum.find(fn x -> Map.has_key?(x, user) end)
  end

  def valid_amount?(amount, currency) do
    is_number(amount) and amount > 0 and valid_currency?(currency)
  end

  def valid_currency?(currency) do
    is_binary(currency) and String.length(currency) != 0
  end

  def find_user_account_by_currency(user, found_user, currency) do
    found_user
    |> Map.get(user)
    |> Enum.find(fn x -> Map.get(x, "currency") == currency end)
  end

  def enough_money_for_withdrawal?(user, found_user, amount, currency) do
    current_amount =
      find_user_account_by_currency(user, found_user, currency)
      |> Map.get("amount")

    money_left = current_amount - amount

    cond do
      money_left < 0 ->
        false

      money_left >= 0 ->
        true
    end
  end
end

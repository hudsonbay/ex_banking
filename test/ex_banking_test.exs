defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  @user "manu"

  test "creates a user succesfully" do
    assert ExBanking.create_user(@user) == :ok
  end

  test "rejects creating a user with wrong arguments" do
    assert ExBanking.create_user("") == {:error, :wrong_arguments}
    assert ExBanking.create_user(1) == {:error, :wrong_arguments}
  end

  test "rejects creating an already existent user" do
    ExBanking.create_user(@user)

    assert ExBanking.create_user(@user) == {:error, :user_already_exists}
  end

  test "deposits 10 EUR into a non-existent EUR account to an existent user, creating the new account" do
    ExBanking.create_user(@user)
    assert ExBanking.deposit(@user, 10, "EUR") == {:ok, 10}
  end

  test "deposits 10.50 EUR into an existent EUR account to an existent user" do
    ExBanking.create_user(@user)
    assert ExBanking.deposit(@user, 10, "EUR") == {:ok, 10}
    assert ExBanking.deposit(@user, 10.50, "EUR") == {:ok, 20.50}
  end

  test "rejects depositing 10 EUR to a non-existent EUR account to a non-existent user" do
    assert ExBanking.deposit(@user, 10, "EUR") == {:error, :user_does_not_exist}
  end

  test "rejects depositing invalid money and amount values to an existent user" do
    ExBanking.create_user(@user)
    assert ExBanking.deposit(@user, 23, "") == {:error, :wrong_arguments}
    assert ExBanking.deposit(@user, "23", "EUR") == {:error, :wrong_arguments}
    assert ExBanking.deposit(@user, -23, "EUR") == {:error, :wrong_arguments}
  end

  test "rejects withdrawing money when the values are invalid" do
    ExBanking.create_user(@user)
    assert ExBanking.withdraw(@user, 23, "") == {:error, :wrong_arguments}
    assert ExBanking.withdraw(@user, "23", "EUR") == {:error, :wrong_arguments}
    assert ExBanking.withdraw(@user, -23, "EUR") == {:error, :wrong_arguments}
  end

  test "rejects withdrawing money of user that doesn't exist when there are existing users in the bank" do
    ExBanking.create_user("george")
    ExBanking.create_user("dimitri")
    assert ExBanking.withdraw(@user, 23, "EUR") == {:error, :user_does_not_exist}
  end

  test "rejects withdrawing money of user when there are no users in the bank" do
    assert ExBanking.withdraw(@user, 23, "EUR") == {:error, :user_does_not_exist}
  end

  test "rejects withdrawing more money than what the user has in the account of the given currency" do
    ExBanking.create_user(@user)
    ExBanking.deposit(@user, 100, "EUR")

    assert ExBanking.withdraw(@user, 200, "EUR") == {:error, :not_enough_money}
  end

  test "rejects withdrawing money in a currency that doesn't have enough $$$ although the user have enough in other currencies" do
    ExBanking.create_user(@user)
    ExBanking.deposit(@user, 500, "EUR")
    ExBanking.deposit(@user, 100, "USD")

    assert ExBanking.withdraw(@user, 200, "USD") == {:error, :not_enough_money}
  end

  test "successfully withdraws money from an account in a given currency" do
    ExBanking.create_user(@user)
    ExBanking.deposit(@user, 500, "EUR")

    assert ExBanking.withdraw(@user, 200, "EUR") == {:ok, 300}
  end
end

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
end

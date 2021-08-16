defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  @user "manu"
  @receiver "tom morello"

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

  test "rejects obtaining balance of a non-existing user when there no users in the bank" do
    assert ExBanking.get_balance(@user, "USD") == {:error, :user_does_not_exist}
  end

  test "rejects obtaining balance of a non-existing user when there users in the bank" do
    ExBanking.create_user("george")
    ExBanking.create_user("dimitri")
    assert ExBanking.get_balance(@user, "USD") == {:error, :user_does_not_exist}
  end

  test "rejects obtaining the balance of an existing user when the given currency is invalid" do
    ExBanking.create_user(@user)
    assert ExBanking.get_balance(@user, "") == {:error, :wrong_arguments}
    assert ExBanking.get_balance(@user, 12) == {:error, :wrong_arguments}
    assert ExBanking.get_balance(@user, :some_currency) == {:error, :wrong_arguments}
  end

  test "rejects obtaining the balance when there's no account of the given currency" do
    ExBanking.create_user(@user)
    ExBanking.deposit(@user, 500, "EUR")
    ExBanking.deposit(@user, 500, "USD")

    assert ExBanking.get_balance(@user, "CAD") == {:error, :wrong_arguments}
  end

  test "succesfully obtains the balance of a user in a given currency" do
    ExBanking.create_user(@user)
    ExBanking.deposit(@user, 500, "EUR")
    ExBanking.deposit(@user, 500, "USD")
    ExBanking.deposit(@user, 600, "USD")

    assert ExBanking.get_balance(@user, "EUR") == {:ok, 500}
    assert ExBanking.get_balance(@user, "USD") == {:ok, 1_100}
  end

  test "rejects sending money with invalid amount values" do
    ExBanking.create_user(@user)
    ExBanking.create_user(@receiver)

    assert ExBanking.send(@user, @receiver, 12, "") == {:error, :wrong_arguments}
    assert ExBanking.send(@user, @receiver, "12", "USD") == {:error, :wrong_arguments}
    assert ExBanking.send(@user, @receiver, 12, :some_currency) == {:error, :wrong_arguments}
  end

  test "rejects sending money when the sender doesn't exist" do
    assert ExBanking.send(@user, @receiver, 12, "USD") == {:error, :sender_does_not_exist}
  end

  test "rejects sending money when the sender doesn't have enough money to send" do
    ExBanking.create_user(@user)
    ExBanking.deposit(@user, 500, "EUR")

    assert ExBanking.send(@user, @receiver, 800, "EUR") == {:error, :not_enough_money}
  end

  test "rejects sending money when the sender doesn't have an account in the given currency" do
    ExBanking.create_user(@user)
    ExBanking.deposit(@user, 500, "EUR")

    assert ExBanking.send(@user, @receiver, 200, "USD") == {:error, :wrong_arguments}
  end

  test "rejects sending money when the receiver doesn't exist" do
    ExBanking.create_user(@user)
    ExBanking.deposit(@user, 500, "EUR")

    assert ExBanking.send(@user, @receiver, 12, "EUR") == {:error, :receiver_does_not_exist}
  end

  test "succesfully sends 10 EUR from one user to a user that doesn't have an EUR account" do
    ExBanking.create_user(@user)
    ExBanking.deposit(@user, 500, "EUR")
    ExBanking.create_user(@receiver)

    assert ExBanking.send(@user, @receiver, 10, "EUR") == {:ok, 490, 10}
  end

  test "succesfully sends 10 EUR from one user to a user that has an EUR account" do
    ExBanking.create_user(@user)
    ExBanking.deposit(@user, 500, "EUR")
    ExBanking.create_user(@receiver)
    ExBanking.deposit(@receiver, 500, "EUR")

    assert ExBanking.send(@user, @receiver, 10, "EUR") == {:ok, 490, 510}
  end
end

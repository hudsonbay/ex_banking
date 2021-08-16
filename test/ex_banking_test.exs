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
end

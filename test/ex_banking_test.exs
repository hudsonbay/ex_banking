defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  @user "manu"

  test "creates a user succesfully" do
    assert ExBanking.create_user(@user) == :ok
  end
end

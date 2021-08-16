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
end

defmodule ExBanking.UserSupervisor do
  @moduledoc """
  This supervisor is responsible for user child processes.
  """
  def supervise_user(user) do
    DynamicSupervisor.start_child(
      ExBanking.DynamicSupervisor,
      {ExBanking, user}
    )
    # |> IO.inspect(label: "supervised child:")

    %{active: active} = DynamicSupervisor.count_children(ExBanking.DynamicSupervisor)

    cond do
      active < 10 ->
        IO.puts("number of active supervised processes: #{active}")
        :ok

      active >= 10 ->
        IO.puts("number of active supervised processes: #{active}")
        :error
    end
  end
end

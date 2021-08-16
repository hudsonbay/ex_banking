defmodule ExBanking do
  use GenServer

  # Client

  def start_link do
    GenServer.start_link(__MODULE__, [:ex_banking], name: __MODULE__)
  end

  # Server (callbacks)

  def init(_) do
    {:ok, []}
  end
end

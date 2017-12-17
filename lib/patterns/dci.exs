defmodule Patterns.DCI.Account do
  defstruct available_balance: nil
end

defmodule Patterns.DCI.BankTransfer do
  alias Patterns.DCI.{MoneySource, MoneyDestination}

  def transfer(amount, %{money_source: source, money_destination: dest}) do
    if MoneySource.has_available_funds?(source, amount) do
      source = MoneySource.subtract_funds(source, amount)
      dest   = MoneyDestination.receive_funds(dest, amount)
      {:ok, %{money_source: source, money_destination: dest}}
    else
      {:error, "insufficient funds"}
    end
  end
end

defprotocol Patterns.DCI.MoneySource do
  def has_available_funds? money_source, amount
  def subtract_funds money_source, amount
end

defprotocol Patterns.DCI.MoneyDestination do
  def receive_funds money_destination, amount
end

defimpl Patterns.DCI.MoneySource, for: Patterns.DCI.Account do
  def has_available_funds?(%Patterns.DCI.Account{available_balance: bal}, amount) when bal >= amount do
    true
  end

  def has_available_funds?(%Patterns.DCI.Account{}, _amount), do: false

  def subtract_funds(%Patterns.DCI.Account{available_balance: bal} = account, amount) do
    %{account | available_balance: bal - amount}
  end
end

defimpl Patterns.DCI.MoneyDestination, for: Patterns.DCI.Account do
  def receive_funds(%Patterns.DCI.Account{available_balance: bal} = account, amount) do
    %{account | available_balance: bal + amount}
  end
end

defmodule Patterns.DCI.Run do
  alias Patterns.DCI.{Account, BankTransfer}

  piet = %Account{available_balance: 10}
  jaap = %Account{available_balance: 15}

  case BankTransfer.transfer 5, %{money_source: piet, money_destination: jaap} do
    {:ok, result} ->
      IO.puts "Successfully transferred 5 from #{inspect result.money_source} to #{inspect result.money_destination}"
    {:error, msg} ->
      IO.puts "Failed to transfer funds: #{msg}"
  end
end

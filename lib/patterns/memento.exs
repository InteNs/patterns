defmodule Patterns.Memento.Memento do
  defstruct state: ""
end

defmodule Patterns.Memento.Originator do
  defstruct state: ""

  alias Patterns.Memento.{Originator, Memento}

  def save(%Originator{} = originator) do
    %Memento{state: originator.state}
  end

  def load(%Memento{} = memento) do
    %Originator{state: memento.state}
  end
end

defmodule Patterns.Memento.CareTaker do
  use Agent

  alias Patterns.Memento.Memento

  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def add(%Memento{} = memento) do
    Agent.update(__MODULE__, fn list -> list ++ [memento] end)
  end

  def get(index) do
    Agent.get(__MODULE__, &Enum.at(&1, index))
  end
end

defmodule Patterns.Memento do
  alias Patterns.Memento.{CareTaker, Originator}

  def set_state(originator, state) do
    %Originator{originator | state: state}
  end

  def save(originator) do
    originator
    |> Originator.save
    |> CareTaker.add

    originator
  end

  def load(_originator, index) do
    index
    |> CareTaker.get
    |> Originator.load
  end

  def get_state(originator, message) do
    IO.puts message<> " " <> originator.state
    originator
  end
end

defmodule Patterns.Memento.Run do
  import Patterns.Memento

  Patterns.Memento.CareTaker.start_link

  %Patterns.Memento.Originator{}
  |> set_state("state #1")
  |> set_state("state #2")
  |> save()
  |> set_state("state #3")
  |> save()
  |> set_state("state #4")
  |> get_state("Current state:")
  |> load(0)
  |> get_state("First state:")
  |> load(1)
  |> get_state("Second state:")
end

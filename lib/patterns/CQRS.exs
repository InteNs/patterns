defmodule Patterns.CQRS.Commands.CreateActivity,  do: defstruct [:id, :type]
defmodule Patterns.CQRS.Commands.PlanActivity,    do: defstruct [:id, :planned_start, :planned_end]
defmodule Patterns.CQRS.Commands.RealiseActivity, do: defstruct [:id, :realised_start, :realised_end]
defmodule Patterns.CQRS.Commands.DeleteActivity,  do: defstruct [:id]

defmodule Patterns.CQRS.Events.ActivityCreated,   do: defstruct [:id, :type]
defmodule Patterns.CQRS.Events.ActivityPlanned,   do: defstruct [:id, :planned_start, :planned_end]
defmodule Patterns.CQRS.Events.ActivityRealised,  do: defstruct [:id, :realised_start, :realised_end]
defmodule Patterns.CQRS.Events.ActivityDelayed,   do: defstruct [:id, :delay_in_hours]
defmodule Patterns.CQRS.Events.ActivityDeleted,   do: defstruct [:id]

defmodule Patterns.CQRS.Activity do
  defstruct id: nil, type: nil, planned_start: nil, planned_end: nil, realised_start: nil, realised_end: nil

  alias __MODULE__

  alias Patterns.CQRS.Commands.{CreateActivity, PlanActivity, RealiseActivity, DeleteActivity}
  alias Patterns.CQRS.Events.{ActivityCreated, ActivityPlanned, ActivityRealised, ActivityDelayed, ActivityDeleted}

  def execute(%Activity{type: nil}, %CreateActivity{id: id, type: type}) do
    %ActivityCreated{id: id, type: type}
  end

  def execute(%Activity{} = _state, %PlanActivity{id: id, planned_start: planned_start, planned_end: planned_end})
    when planned_end >= planned_start
  do
    %ActivityPlanned{id: id, planned_start: planned_start, planned_end: planned_end}
  end

  def execute(%Activity{planned_end: planned_end}, %RealiseActivity{id: id, realised_start: realised_start, realised_end: realised_end})
    when realised_end >= realised_start
  do
    realised = %ActivityRealised{id: id, realised_start: realised_start, realised_end: realised_end}

    if (NaiveDateTime.compare(realised_end, planned_end) == :gt) do
      delay_in_hours = NaiveDateTime.diff(planned_end, realised_end) / 60 / 60
      [realised, %ActivityDelayed{id: id, delay_in_hours: delay_in_hours}]
    else
      realised
    end
  end

  def execute(%Activity{}, %DeleteActivity{id: id}) do
    %ActivityDeleted{id: id}
  end

  def apply(%Activity{} = state, %ActivityCreated{id: id, type: type}) do
    IO.puts "#{type} activity #{id} created"
    %Activity{state | id: id, type: type}
  end

  def apply(%Activity{} = state, %ActivityPlanned{id: id, planned_start: planned_start, planned_end: planned_end}) do
    IO.puts "activtity #{id} planned from #{inspect planned_start} to #{inspect planned_end}"
    %Activity{state | planned_start: planned_start, planned_end: planned_end}
  end

  def apply(%Activity{} = state, %ActivityRealised{id: id, realised_start: realised_start, realised_end: realised_end}) do
    IO.puts "activity #{id} realised from #{inspect realised_start} to #{inspect realised_end}"
    %Activity{state | realised_start: realised_start, realised_end: realised_end}
  end

  def apply(%Activity{} = state, %ActivityDelayed{id: id, delay_in_hours: delay}) do
    IO.puts "activity #{id} was delayed #{delay} hours"
    state
  end

  def apply(%Activity{}, %ActivityDeleted{id: id}) do
    IO.puts "activity #{id} was deleted"
    %Activity{id: nil, type: nil}
  end
end

defmodule Patterns.CQRS.Run do
  alias Patterns.CQRS.Activity
  alias Patterns.CQRS.Commands.{CreateActivity, PlanActivity, RealiseActivity, DeleteActivity}

  activity = %Activity{}
  IO.puts "state: #{inspect activity}\n"

  commands = [
    %CreateActivity{ id: "1", type: "train"},
    %PlanActivity{   id: "1", planned_start: ~N[2017-12-12 10:00:00], planned_end: ~N[2017-12-12 18:00:00]},
    %RealiseActivity{id: "1", realised_start: ~N[2017-12-12 12:00:00], realised_end: ~N[2017-12-12 22:00:00]},
    %DeleteActivity{ id: "1"}
  ]

  activity = Enum.reduce commands, activity, fn command, state ->
    state  = Activity.execute(state, command)
    |> List.wrap
    |> Enum.reduce(state, fn e, state -> Activity.apply(state, e) end)

    IO.puts "state: #{inspect state}\n"
    state
  end

  IO.puts "state: #{inspect activity}"
end

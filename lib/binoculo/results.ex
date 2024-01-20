defmodule Binoculo.Results do
  @moduledoc """
  Store workers results
  """

  @table_name :worker_control
  @running_key :worker_in_progress
  @finished_key :worker_finished
  @qty_running_key :worker_qty_running

  @spec init_db() :: boolean()
  def init_db() do
    case is_started?() do
      true ->
        :already_started

      _ ->
        :ets.new(@table_name, [:set, :public, :named_table])
        :ets.insert(@table_name, {@running_key, []})
        :ets.insert(@table_name, {@finished_key, []})
        :ets.insert(@table_name, {@qty_running_key, 0})
    end
  end

  def delete_db(), do: :ets.delete(@table_name)

  def is_started?() do
    case :ets.info(@table_name) do
      :undefined -> false
      _ -> true
    end
  end

  @spec add_item(any) :: atom()
  def add_item(item) do
    in_progress =
      :ets.lookup(@table_name, @running_key)
      |> Keyword.get(@running_key)

    in_progress = [item | in_progress]
    :ets.insert(@table_name, {@running_key, in_progress})
    :ets.update_counter(@table_name, @qty_running_key, 1)
    :ok
  end

  def finish_item(item) do
    remove_item(item)
    finished_updated = [item | get_finished()]
    :ets.insert(@table_name, {@finished_key, finished_updated})
  end

  def remove_item(item) do
    running_updated =
      get_running()
      |> Enum.filter(fn %{host: host} -> host != item[:host] end)

    :ets.insert(@table_name, {@running_key, running_updated})
    :ets.update_counter(@table_name, @qty_running_key, -1)
  end

  def get_state() do
    :ets.select(
      @table_name,
      for(key <- [@running_key, @finished_key, @qty_running_key], do: {{key, :_}, [], [:"$_"]})
    )
  end

  def get_running() do
    get_state()
    |> Keyword.get(@running_key)
  end

  def get_qty_running() do
    get_state()
    |> Keyword.get(@qty_running_key)
  end

  def get_finished() do
    get_state()
    |> Keyword.get(@finished_key)
  end
end

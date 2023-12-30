defmodule Binoculo.Config do
  @moduledoc """
    Genserver to store user configs
  """

  use GenServer

  @initial_state %{
    output_file: "output/result"
  }

  def start_link(config) do
    GenServer.start_link(__MODULE__, Map.merge(@initial_state, config), name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def set_output_file(file_name) do
    file_name = "output/#{file_name}"
    GenServer.cast(__MODULE__, {:set_output_file, file_name})
  end

  def get_output_file() do
    GenServer.call(__MODULE__, :get_output_file)
  end

  def handle_cast({:set_output_file, file_name}, state) do
    {:noreply, Map.put(state, :output_file, file_name)}
  end

  def handle_call(:get_output_file, _from, state) do
    {:reply, state[:output_file], state}
  end
end

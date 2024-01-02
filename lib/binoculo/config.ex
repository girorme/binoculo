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

  def set_write_payload(payload) do
    GenServer.cast(__MODULE__, {:set_write_payload, payload})
  end

  def get_write_payload() do
    GenServer.call(__MODULE__, :get_write_payload)
  end

  def set_read_payload(payload) do
    GenServer.cast(__MODULE__, {:set_read_payload, payload})
  end

  def get_read_payload() do
    GenServer.call(__MODULE__, :get_read_payload)
  end

  def handle_cast({:set_output_file, file_name}, state) do
    {:noreply, Map.put(state, :output_file, file_name)}
  end

  def handle_cast({:set_write_payload, payload}, state) do
    {:noreply, Map.put(state, :write_payload, payload)}
  end

  def handle_cast({:set_read_payload, payload}, state) do
    {:noreply, Map.put(state, :read_payload, payload)}
  end

  def handle_call(:get_output_file, _from, state) do
    {:reply, state[:output_file], state}
  end

  def handle_call(:get_write_payload, _from, state) do
    {:reply, state[:write_payload], state}
  end

  def handle_call(:get_read_payload, _from, state) do
    {:reply, state[:read_payload], state}
  end
end

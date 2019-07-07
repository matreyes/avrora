defmodule Avrora.MemoryStorage do
  @moduledoc """
  Fast in-memory storage of schemas with access by global id or full name.
  """

  use GenServer

  @behaviour Avrora.Storage
  @ets_opts [
    :private,
    :set,
    :compressed,
    {:read_concurrency, true},
    {:write_concurrency, true}
  ]

  def start_link(opts \\ []) do
    {name_opts, _} = Keyword.split(opts, [:name])
    opts = Keyword.merge([name: __MODULE__], name_opts)

    GenServer.start_link(__MODULE__, [], opts)
  end

  @impl true
  def init(_state \\ []) do
    {:ok, [table: :ets.new(nil, @ets_opts)]}
  end

  @impl true
  def handle_cast({:put, key, value}, state) do
    {:ok, table} = Keyword.fetch(state, :table)

    true = :ets.insert(table, {key, value})
    {:noreply, state}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    {:ok, table} = Keyword.fetch(state, :table)

    case :ets.lookup(table, key) do
      [{_, value}] -> {:reply, value, state}
      _ -> {:reply, nil, state}
    end
  end

  @doc """
  Stores a value with a given key. If the value is already exists it will be replaced.

  ## Examples
      iex> {:ok, _} = Avrora.MemoryStorage.start_link()
      iex> Avrora.MemoryStorage.put("my-key", %{"hello" => "world"})
      {:ok, %{"hello" => "world"}}
  """
  def put(key, value), do: put(__MODULE__, key, value)

  @doc false
  @spec put(pid() | atom(), String.t() | integer(), term()) :: {:ok, term()} | {:error, term()}
  def put(pid, key, value), do: {GenServer.cast(pid, {:put, key, value}), value}

  @doc """
  Retrieve a value by a given key.

  ## Examples
      iex> {:ok, _} = Avrora.MemoryStorage.start_link()
      iex> Avrora.MemoryStorage.put("my-key", %{"hello" => "world"})
      {:ok, %{"hello" => "world"}}
      iex> Avrora.MemoryStorage.get("my-key")
      {:ok, %{"hello" => "world"}}
      iex> Avrora.MemoryStorage.get("unknown-key")
      {:ok, nil}
  """
  @spec get(String.t() | integer()) :: nil | term()
  def get(key), do: get(__MODULE__, key)

  @doc false
  @spec get(pid() | atom(), String.t() | integer()) :: {:ok, term()} | {:error, term()}
  def get(pid, key), do: {:ok, GenServer.call(pid, {:get, key})}
end

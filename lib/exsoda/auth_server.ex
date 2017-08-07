defmodule Exsoda.AuthServer do
  use GenServer

  @clear_timeout 10 * 60 * 1000

  defmodule State do
    defstruct pending: %{}, cookies: %{}
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    :timer.apply_interval(@clear_timeout, __MODULE__, :clear_cookies, [])
    {:ok, %State{}}
  end

  def get_cookie(opts) do
    GenServer.call(__MODULE__, {:get_cookie, opts})
  end

  def list_cookies() do
    GenServer.call(__MODULE__, :list_cookies)
  end

  def clear_cookies() do
    GenServer.cast(__MODULE__, :clear_cookies)
  end

  def handle_call({:get_cookie, opts}, reply, %State{pending: pending, cookies: cookies} = state) do
    key = Map.take(opts, [:host, :domain, :api_root, :protocol, :spoof])
    case cookies[key] do
      nil ->
        {worker, _ref} = spawn_monitor(fn ->
          result = Exsoda.Http.get_cookie_impl(opts)
          GenServer.cast(__MODULE__, {:cookie_result, self(), reply, key, result})
        end)
        {:noreply, %State{state | pending: Map.put(pending, worker, reply)}}
      cookie ->
        {:reply, {:ok, cookie}, state}
    end
  end

  def handle_call(:list_cookies, _, %State{cookies: cookies} = state) do
    {:reply, cookies, state}
  end

  def handle_cast(:clear_cookies, %State{} = state) do
    {:noreply, %State{state | cookies: %{}}}
  end

  def handle_cast({:cookie_result, worker, reply, key, {:ok, cookie} = response}, %State{pending: pending, cookies: cookies} = state) do
    GenServer.reply(reply, response)
    {:noreply, %State{state | pending: Map.delete(pending, worker),
                              cookies: Map.put(cookies, key, cookie)}}
  end
  def handle_cast({:cookie_result, worker, reply, _key, response}, %State{pending: pending} = state) do
    GenServer.reply(reply, response)
    {:noreply, %State{state | pending: Map.delete(pending, worker)}}
  end

  def handle_info({:DOWN, _ref, _type, pid, info}, %State{pending: pending} = state) do
    case Map.get(pending, pid) do
      nil ->
        {:noreply, state}
      reply ->
        GenServer.reply(reply, {:error, info})
        {:noreply, %State{state | pending: Map.delete(pending, pid)}}
    end
  end
end

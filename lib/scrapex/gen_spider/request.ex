defmodule Scrapex.GenSpider.Request do
  @moduledoc """
  Conveniences for spawing and awaiting for HTTP requests.

  Requests are processes meant to perform one particular HTTP request
  to a specific URL throughout their life-cycle, often with little or
  no communication with other processes.

  Requests spawned with `async/2` can be awaited on by its caller
  process (and only its caller). They are implemented  by spawing a
  `Task` and await on it.
  """
  alias Scrapex.GenSpider.Request
  alias Scrapex.GenSpider.Response
  require Logger

  @doc """
  The Request struct.

  It contains the following fields:

    * `:pid` - the process reference of the request process.

    * `:ref` - the request monitor reference

    * `:url` - the url to make request to
  """
  defstruct pid: nil, ref: nil, url: ""
  @type t :: %__MODULE__{pid: pid, ref: reference, url: binary}

  @type url :: binary

  @doc """
  Starts an asynchronous request that can be awaited on.

  This function spawns a Task that is linked to and monitored by the
  caller process. A `Request` struct is returned as an extended version
  of the `Task` struct.

  ## Request's message format

  The reply sent by the request will be the of the underlying `Task`,
  i.e., in the format `{ref, msg}`, where `ref` is the monitoring ref
  held by the request, and `msg` is the return value of the callback.
  """
  @spec async(url, fun, pid) :: t
  def async(url, callback, from \\ self) when is_pid(from) do
    mfa = {:erlang, :apply, [&request/2, [url, callback]]}
    pid = :proc_lib.spawn_link(Task.Supervised, :async, [from, get_info(from), mfa])
    ref = Process.monitor(pid)
    send(pid, {from, ref})
    %Request{url: url, pid: pid, ref: ref}
  end

  @doc """
  Awaits a request response.

  A timeout in milliseconds can be given with default value of `5000`.
  In case the request process dies, this function will exit with the 
  same reason as the request.
  """
  @spec await(t, timeout) :: term
  def await(%Request{pid: pid, ref: ref}, timeout \\ 5000) do
    Task.await(%Task{pid: pid, ref: ref}, timeout)
  end

  defp get_info(pid) do
    {node(),
     case Process.info(pid, :registered_name) do
       {:registered_name, []} -> pid
       {:registered_name, name} -> name
     end}
  end

  defp request(url, callback) do
    case do_request(url) do
      # HTTP Request succeeded, return whatever the callback returns.
      {:ok, response} ->
        response |> callback.()
      # Forward the HTTP error to the `handle_info`
      {:error, reason} -> 
        {:error, reason}
    end
  end

  defp do_request(url) do
    Logger.debug("Do request for #{url}")
    hackney = [follow_redirect: true, timeout: 30000, recv_timeout: 15000]
    case HTTPoison.get(url, [], [ hackney: hackney ]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, %Response{url: url, body: body}}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, {:not_found, url}}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
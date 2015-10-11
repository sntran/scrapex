defmodule Scrapex.GenSpider do
  alias Scrapex.GenSpider
  require Logger
  @moduledoc """
  A behaviour module for implementing a web data extractor.

  A GenSpider is a process as any other Elixir process and it can be
  used to crawl a list of URLs, run callback to parse the response,
  and repeat on an interval.

  ## Example

  The GenSpider behaviour abstracts the common data extraction process.
  Users are only required to implement the callbacks and functionality
  they are interested in.

  Imagine we want a GenSpider that takes a list of selectors exported
  from http://webscraper.io/ and follow them to get the data.

      defmodule WebScrapper do
        use GenSpider

        # Callbacks

        def init(%{"selectors"=> selectors}) do
          %{"selectors" => selectors, "data" => []}
        end
        
        def parse(response, %{"selectors" => selectors}) do
          # Wrap the HTML with a Css selector engine.
          engine = GenSpider.CssSelector(response)
          Enum.map(selectors, fn(selector) ->
            selector
            |> engine.select()
            |> engine.extract()
          end)
        end
      end

      # Start the spider
      sitemap = File.read!("sitemap.json") |> Poison.decode!
      opts =  name: :webscrapper,
              urls: [sitemap["siteUrl"]], 
              interval: 3600
      {:ok, pid} = GenSpider.start_link(WebScrapper, sitemap, opts)


      # This is the client
      GenSpider.export(pid, :json)
      #=> "[{} | _]"

  We start our `WebScrapper` by calling `start_link/3`, passing the
  module with the spider implementation and its initial argument (a
  list representing the selectors to follow and grab). We also pass
  a option list to register the spider with a name, and a list of urls
  to start following, and an interval for refetching.

  We can get the data from the spider by calling `GenSpider.export/2`
  with the `pid` of the spider, and the output format. `GenSpider`
  supports outputting JSON, CSV and XML. 

  ## Callbacks

  There are 3 callbacks required to be implemented in a `GenSpider`.
  By adding `use GenSpider` to your module, all 6 callbacks will be
  automatically defined, leaving it up to you to implement the ones
  you want to customize. The callbacks are:

    * `init(args)` - invoked when the spider is started.

      It must return:
      -  `{:ok, state}`
      -  `{:ok, state, delay}`
      -  `:ignore`
      -  `{:stop, reason}`

    * `parse(response, state)` - invoked after the spider has requested
      a URL successfully with a HTML in `response`.

      It must return:
      -  `{:ok, new_state}`
      -  `{:ignore, new_state}`
      -  `{:stop, reason, new_state}`

    * `handle_export(type, state)` - invoked to handle `export` call.

      It must return:
      -  `{:ok, data, new_state}`
      -  `{:stop, reason, new_state}`
      -  `{:stop, reason, data, new_state}`

    * `terminate(reason, state)` - called when the server is about to
      terminate, useful for cleaning up. It must return `:ok`.

    * `code_change(old_vsn, state, extra)` - called when the application
      code is being upgraded live (hot code swapping).

      It must return:
      -  `{:ok, new_state}`
      -  `{:error, reason}`

  ## Client / Server APIs

  Although in the example above we have used `GenSpider.start_link/3`
  and friends to directly start and communicate with the spider, most 
  of the time we don't call the `GenSpider` functions directly.
  Instead, we wrap the calls in new functions representing the public
  API of the spider.

  Here is a better implementation of our WebScrapper module:

      defmodule WebScrapper do
        use GenSpider

        # Client
        def start_link(sitemap) do
          opts =  [name: :webscrapper,
              urls: [sitemap["siteUrl"]], 
              interval: 3600]
          GenSpider.start_link(__MODULE__, sitemap, opts)
        end

        def json(pid) do
          GenSpider.export(pid, :json)
        end
        
        # Server (callbacks)

        def init(%{"selectors"=> selectors}) do
          %{"selectors" => selectors, "data" => []}
        end
        
        def parse(response, %{"selectors" => selectors}) do
          # Wrap the HTML with a Css selector engine.
          engine = GenSpider.CssSelector(response)
          Enum.map(selectors, fn(selector) ->
            selector
            |> engine.select()
            |> engine.extract()
          end)
        end

        def handle_export(:json, state) do
          # Call the default implementation from GenSpider
          super(:json, state)
        end
      end

  In practice, it is common to have both server and client functions in
  the same module. If the server and/or client implementations are 
  growing complex, you may want to have them in different modules.
  """

  @typedoc "Options used by the `start*` functions"
  @type options :: [options]

  @type option :: {:name, GenServer.name} |
                  {:timeout, timeout} |
                  {:interval, non_neg_integer}

  @typedoc "The spider reference"
  @type spider :: pid | GenServer.name | {atom, node}

  @typedoc "The internal state of the spider"
  @type state :: any

  @typedoc "The response from a request to a URL"
  @type response :: binary

  @typedoc "Exportable formats"
  @type format :: :html | :json | :csv | :xml

  # `GenSpider` is based on `GenServer`.
  use GenServer

  # Define the callbacks for `GenSpider`
  @callback init(any) ::
    {:ok, state} | {:ok, state, timeout | :hibernate} |
    :ignore | {:stop, reason :: term}

  @callback parse(response, state) ::
    {:ok, state} | {:ignore, state} |
    {:stop, reason :: term, state}

  @callback handle_export(format, state) ::
    {:ok, any, state} |
    {:stop, reason :: term, state} | {:stop, reason :: term, any, state}

  @doc """
  This callback is the same as the `GenServer` equivalent and is used to change
  the state when loading a different version of the callback module.
  """
  @callback code_change(any, any, state) :: {:ok, state}

  @doc """
  This callback is the same as the `GenServer` equivalent and is called when the
  process terminates. The first argument is the reason the process is about
  to exit with.
  """
  @callback terminate(any, state) :: any

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour GenSpider

      @doc false
      def init(args) do
        {:ok, args}
      end

      @doc false
      def parse(response, state) do
        # We do this to trick dialyzer to not complain about non-local returns.
        reason = {:bad_call, response}
        case :erlang.phash2(1, 1) do
          0 -> exit(:normal)
          1 -> {:stop, reason, state}
        end
      end

      @doc false
      def handle_export(_type, state) do
        # We do this to trick dialyzer to not complain about non-local returns.
        reason = :bad_call
        case :erlang.phash2(1, 1) do
          0 -> exit(:normal)
          1 -> {:stop, reason, state}
        end
      end

      @doc false
      def terminate(_reason, _state) do
        :ok
      end

      @doc false
      def code_change(_old, state, _extra) do
        {:ok, state}
      end

      defoverridable [init: 1, parse: 2, handle_export: 2,
                      terminate: 2, code_change: 3]
    end
  end

  defstruct module: nil, state: nil, 
            options: [], data: [], requests: [], timer: nil

  @doc """
  Starts a `GenSpider` process linked to the current process.

  This is often used to start the `GenSpider` as part of a supervision 
  tree.

  Once the spider is started, it calls the `init/1` function in the 
  given `module` passing the given `args` to initialize it. To ensure 
  a synchronized start-up procedure, this function does not return 
  until `init/1` has returned.

  Note that a `GenSpider` started with `start_link/3` is linked to the
  parent process and will exit in case of crashes. The GenSpider will 
  also exit due to the `:normal` reasons in case it is configured to 
  trap exits in the `init/1` callback.

  ## Options

  The `:name` option is used for name registration as described in the 
  module documentation. If the option `:timeout` option is present, 
  the spider is allowed to spend the given milliseconds initializing 
  or it will be terminated and the start function will return 
  `{:error, :timeout}`.

  The `:urls` defines a list of URLs for the spider to start from.

  If the `:inverval` option is present, the spider will repeat itself
  after every number of seconds defined by the option. Note that it
  will only repeat if it's not currently running a crawl.

  ## Return values

  If the spider is successfully created and initialized, the function 
  returns `{:ok, pid}`, where pid is the pid of the spider. If there 
  already exists a process with the specified spider name, the 
  function returns `{:error, {:already_started, pid}}` with the pid of 
  that process.

  If the `init/1` callback fails with `reason`, the function returns
  `{:error, reason}`. Otherwise, if it returns `{:stop, reason}`or 
  `:ignore`, the process is terminated and the function returns
  `{:error, reason}` or `:ignore`, respectively.
  """
  @spec start_link(module, any, options) :: GenServer.on_start
  def start_link(module, args, options \\ []) 
  when is_atom(module) and is_list(options) 
  do
    do_start(:start_link, module, args, options)
  end

  @doc """
  Starts a `GenSpider` without links (outside of a supervision tree).
  See `start_link/3` for more information.
  """
  @spec start(module, any, options) :: GenServer.on_start
  def start(module, args, options \\ []) 
  when is_atom(module) and is_list(options)
  do
    do_start(:start, module, args, options)
  end

  @doc false
  defp do_start(link, module, args, options) do
    {name, opts} = Keyword.pop(options, :name)
    init_args = {module, args, opts}
    case name do
      nil ->
        apply(GenServer, link, [__MODULE__, init_args])
      atom when is_atom(atom) ->
        apply(GenServer, link, [__MODULE__, init_args, [name: atom]])
      {:global, _} ->
        apply(GenServer, link, [__MODULE__, init_args, [name: name]])
      {:via, _, _} ->
        apply(GenServer, link, [__MODULE__, init_args, [name: name]])
    end
  end

  @doc """
  Exports the stored data with specific format.

  This call will block until all data received.

  This is called in the following situations:

  - Right after spider is started.
  - In the middle of a crawl.
  - In between the crawl interval.

  For the first two situations, the spider will manually awaits the
  requests instead of handle the response message in `handle_info/2`.

  If one of the `parse/2` callbacks wants to stop the spider, this
  function will still return partial data if any, and then stops the
  spider.

  If the third argument is true, the spider will clear any timer in
  place and immediately crawl for new data.
  """
  @spec export(spider, format, boolean) :: any
  def export(spider, format \\ nil, override \\ false) do
    # Await for all the data to be collected first.
    GenServer.call(spider, :await)
    GenServer.call(spider, {:export, format, override})
  end

  # GenServer callbacks

  def init({module, args, opts}) do
    spider = %GenSpider{  module: module, options: opts, 
                          timer: :erlang.make_ref()}
    urls = opts[:urls] || []
    # Set an empty data set with each URLs as keys.
    data = Enum.map(urls, &({&1, nil}))

    case apply(module, :init, [args]) do
      {:ok, state} ->
        # Return 0 timeout to trigger crawl immediately.
        # This works regardless of interval option, since we always
        # have a crawl. A crawl will use interval option to see if it
        # needs to do the next one.
        # send_after(self, 0, :crawl)
        Logger.debug "Starts a spider immediately"
        {:ok, %{spider | state: state, data: data}, 0}
      {:ok, state, delay} ->
        # Delay the crawl by the value specified in return.
        # send_after(self, delay, :crawl)
        Logger.debug "Starts a spider after #{delay} milliseconds"
        {:ok, %{spider | state: state, data: data}, delay}
      :ignore ->
        :ignore
      {:stop, reason} ->
        {:stop, reason}
      other ->
        other
    end
  end

  @doc """
  Await for any remaining request(s) to finish.

  For any remaining requests in the state, await for them to finish.
  This function will receive the response instead of the `handle_info`
  so it then calls the `handle_info` so that the request can be removed
  from state and the response can be parsed by the callback module.

  This function can be called in the middle of a crawl of multiple URLs
  but since it only awaits the remaning requests, the spider's state
  is still being passed along correctly.
  """
  def handle_call(:await, _from, spider) do
    spider = 
      spider.requests
      |> Enum.reduce_while(spider, fn(request, spider) ->
        ref = request.ref
        response = Task.await(request)
        case handle_info({ref, response}, spider) do
          {:noreply, spider} ->
            {:cont, spider}
          {:stop, _reason, spider} ->
            {:halt, spider}
        end
      end)
    Logger.debug("Awaited for data")
    {:reply, :ok, spider}
  end

  @doc """
  Called to export the data in a specific format.
  """
  def handle_call({:export, nil, true}, from, spider) do
    :erlang.cancel_timer(spider.timer)
    {:noreply, spider} = handle_info(:crawl, spider)
    {:reply, :ok, spider} = handle_call(:await, from, spider)
    handle_call({:export, nil, false}, from, spider)
  end

  def handle_call({:export, nil, false}, _from, spider) do
    Logger.debug("Exporting data")
    
    data = 
      spider.data
      |> Enum.filter_map(fn({_,data}) -> data !== nil end, 
                        fn({_, data}) -> data end)

    is_partial? = length(data) !== length(spider.data)
    data = Enum.concat(data)
    case is_partial? do
      false ->
        {:reply, data, spider}
      true ->
        {:stop, :normal, data, spider}
    end
  end

  def handle_call({:export, :json, override?}, from, spider) do
    {_, data, _} = handle_call({:export, nil, override?}, from, spider)
    {:reply, Poison.encode!(data), spider}
  end

  def handle_call({:export, encoder, override?}, from, spider) 
  when is_function(encoder, 1) 
  do
    {_, data, _} = handle_call({:export, nil, override?}, from, spider)
    {:reply, encoder.(data), spider}
  end

  def handle_call({:export, _format, true}, _from, spider) do
    {:reply, spider.data, spider}
  end
  

  @doc """
  Called when a timeout occurs, usually when to start a crawl.

  The `GenSpider` uses the timeout value to trigger a crawl, in which
  it spawns a task for each URLs specified in the `opts`.

  The results will be handled in a different function.
  """
  def handle_info(:timeout, spider) do
    handle_info(:crawl, spider)
  end

  @doc """
  Called from a timer to crawl a list of URLs.

  This generates a list of async requests to the URLs. The response 
  will be sent back in another message.
  """
  def handle_info(:crawl, spider) do
    options = spider.options
    urls = options[:urls] || []

    Logger.debug "Crawling #{Enum.join(urls, ", ")}"

    requests = urls
    |> Enum.map(&Task.async(fn -> request(&1) end))

    {:noreply, %{spider | requests: requests}}
  end

  @doc """
  Called when a request is completed.

  When a request is completed, i.e. receives the response, this process
  receives a message with the result. We then call the `parse` function
  of the callback module.

  If this is for the last request, it sets a new timer if needed.
  """
  def handle_info({ref, {:ok, result, url}}, spider) do
    Logger.debug "Got data from #{url}"

    requests = spider.requests
    # Remove this request from the list.
    requests = Enum.filter(requests, &(&1.ref !== ref))
    spider = %{spider | requests: requests}

    case apply(spider.module, :parse, [result, spider.state]) do
      {:stop, reason, new_state} ->
        Logger.debug "Spider is stopped with reason #{reason}"
        {:stop, :normal, %{spider | state: new_state}}
      {:ok, data, new_state} ->

        new_data = List.keystore(spider.data, url, 0, {url, data})
        interval = spider.options[:interval]
        spider = case length(requests) === 0 do
          true ->
            # Start a new crawl.
            urls = spider.options[:urls] || []
            :erlang.cancel_timer(spider.timer)
            timer = send_after(self, interval, :crawl)
            %{spider | timer: timer}
          false -> spider
        end
        {:noreply, %{spider | state: new_state, data: new_data}}
    end
  end

  def handle_info(_info, state) do
    {:noreply, state}
  end

  defp request(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body, url}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp send_after(_dest, nil, _message) do
    :erlang.make_ref()
  end
  defp send_after(dest, time, message) do
    :erlang.send_after(time, dest, message)
  end
end
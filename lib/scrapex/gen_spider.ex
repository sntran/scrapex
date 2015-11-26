defmodule Scrapex.GenSpider do
  alias Scrapex.GenSpider
  alias GenSpider.Request

  require Logger
  @moduledoc ~S"""
  A behaviour module for implementing a web data extractor.

  A GenSpider is a process as any other Elixir process and it can be
  used to crawl a list of URLs, run callback to parse the response,
  and repeat on an interval.

  ## Example

  The GenSpider behaviour abstracts the common data extraction process.
  Users are only required to implement the callbacks and functionality
  they are interested in.

  Imagine we want a GenSpider that follows the links to the top voted 
  questions on StackOverflow and scrapes some data from each page:

      iex> alias Scrapex.GenSpider
      iex> defmodule StackOverflowSpider do
      ...>   use GenSpider
      ...>   import Scrapex.Selector
      ...>   
      ...>   def parse(response) do
      ...>     result = response.body
      ...>     |> select(".question-summary h3 a")
      ...>     |> extract("href")
      ...>     |> Enum.map(fn(href) ->
      ...>       GenSpider.Response.url_join(response, href)
      ...>       |> GenSpider.request(&parse_question/1)
      ...>       |> GenSpider.await
      ...>     end)
      ...>     {:ok, result}
      ...>   end
      ...> 
      ...>   defp parse_question(response) do
      ...>     html = response.body
      ...>     [title] = html |> select("h1 a") |> extract()
      ...>     question = html |> select(".question")
      ...>     [body] = question |> select(".post-text") |> extract
      ...>     [votes] = question |> select(".vote-count-post") |> extract
      ...>     tags = question |> select(".post-tag") |> extract
      ...>     
      ...>     %{title: title, body: body, votes: votes, tags: tags}
      ...>   end
      ...> end
      iex> urls = ["http://stackoverflow.com/questions?sort=votes"]
      iex> opts = [name: :webscrapper, urls: urls]
      iex> {:ok, spider} = GenSpider.start_link(StackOverflowSpider, [], opts)
      iex> [top_question|_] = GenSpider.export(spider)
      iex> top_question.title
      "Why is processing a sorted array faster than an unsorted array?"


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

    * `start_requests(state)` - called by Scrapy when the spider is 
      opened for scraping when no particular URLs are specified.  If 
      particular URLs are specified, the `make_requests_from_url/1`
      is used instead to create the Requests. This method is also 
      called only once from Scrapex, so it’s safe to implement it as 
      a stream.

      The default implementation uses `make_requests_from_url/1` to 
      generate Requests for each url in `options.urls`.

    * `make_requests_from_url(url)` - returns a Request object (or a 
      list of Request objects) to scrape. It is used to construct the 
      initial requests in  `start_requests/1`, and is typically used to 
      convert urls to requests.

      Unless overridden, this method returns Requests with `parse/2 as 
      their callback function.

    * `parse(response)` - invoked after the spider has requested
      a URL successfully with a HTML in `response`.

      It must return:
      -  `{:ok, result}`
      -  `{:ignore, reason}`
      -  `{:stop, reason}`

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

  Here is a better implementation of our StackOverflowSpider module:

      defmodule StackOverflowSpider do
        use GenSpider

        # Client
        def start_link(sitemap) do
          urls = ["http://stackoverflow.com/questions?sort=votes"]
          opts =  [name: :stackoverflow, urls: urls, interval: 3600]
          GenSpider.start_link(__MODULE__, [], opts)
        end

        def json(pid) do
          GenSpider.export(pid, :json)
        end
        
        # Server (callbacks)

        def parse(response) do
          result = response.body
          |> select(".question-summary h3 a")
          |> extract("href")
          |> Enum.map(fn(href) ->
            GenSpider.Response.url_join(response, href)
            |> GenSpider.request(&parse_question/1)
            |> GenSpider.await
          end)
          {:ok, result]}
        end

        defp parse_question(response) do
          html = response.body
          [title] = html |> select("h1 a") |> extract()
          question = html |> select(".question")
          [body] = question |> select(".post-text") |> extract
          [votes] = question |> select(".vote-count-post") |> extract
          tags = question |> select(".post-tag") |> extract
          
          %{title: title, body: body, votes: votes, tags: tags}
        end
      end

  In practice, it is common to have both server and client functions in
  the same module. If the server and/or client implementations are 
  growing complex, you may want to have them in different modules.
  """

  @typedoc "Options used by the `start*` functions"
  @type options :: [options]

  @type url :: binary

  @type option :: {:name, GenServer.name} |
                  {:urls, [url]} |
                  {:timeout, timeout} |
                  {:interval, non_neg_integer}

  @typedoc "The spider reference"
  @type spider :: pid | GenServer.name | {atom, node}

  @typedoc "The internal state of the spider"
  @type state :: any

  @typedoc "The list of requests or stream for the spider to enumerate"
  @type requests :: Request.t | [Request.t] | Stream.t

  @typedoc "The response from a request to a URL"
  @type response :: binary

  @typedoc "Exportable formats"
  @type format :: :html | :json | :csv | :xml

  @type t :: %__MODULE__{module: atom, 
                         state: any, 
                         options: Keyword.t,
                         data: [{url, any}],
                         requests: requests,
                         timer: reference}
  defstruct module: nil, state: nil, 
            options: [], data: [], requests: [], timer: nil

  # `GenSpider` is based on `GenServer`.
  use GenServer

  # Define the callbacks for `GenSpider`
  @callback init(any) ::
    {:ok, state} | {:ok, state, timeout | :hibernate} |
    :ignore | {:stop, reason :: term}

  @callback start_requests([url], state) ::
    {:ok, requests, state}

  @callback make_requests_from_url(url) :: requests

  @callback parse(response) ::
    {:ok, data :: list} | {:ignore, reason :: term} |
    {:stop, reason :: term}

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

      @start_urls []

      @doc false
      def init(args) do
        {:ok, args}
      end

      @doc """
      Default method to generate the first Requests to crawl.

      Uses `make_requests_from_url/1` to generate Requests for each 
      url in `start_urls`.
      """
      def start_requests(start_urls, state) do
        requests = start_urls
        |> Enum.map(&make_requests_from_url/1)
        {:ok, requests, state}
      end

      @doc """
      Default method to generate a Request (or a list of Requests).
      """
      def make_requests_from_url(url) do
        GenSpider.request(url, &parse/1)
      end

      @doc false
      def parse(response) do
        {:ok, [response.body]}
      end

      @doc false
      def terminate(_reason, _state) do
        :ok
      end

      @doc false
      def code_change(_old, state, _extra) do
        {:ok, state}
      end

      defoverridable [init: 1, 
                      start_requests: 2, 
                      make_requests_from_url: 1,
                      parse: 1,
                      terminate: 2, code_change: 3]
    end
  end

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

  If one of the `parse/1` callbacks wants to stop the spider, this
  function will still return partial data if any, and then stops the
  spider.

  If the third argument is true, the spider will clear any timer in
  place and immediately crawl for new data.
  """
  @spec export(spider, format, boolean) :: any
  def export(spider, format \\ nil, override \\ false) do
    # Await for all the data to be collected first.
    GenServer.call(spider, :await, :infinity)
    GenServer.call(spider, {:export, format, override})
  end

  def request(url, callback, from \\ self) do
    Request.async(url, callback, from)
  end
  defdelegate await(request), to: Request

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
        response = Request.await(request, :infinity)
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

    args = [urls, spider.state]
    spider = case call(:start_requests, spider, args) do
      {:ok, requests, state} ->
        # `requests` can also be a `Stream`.
        %{spider |  requests: Enum.map(requests, &(&1)), 
                    state: state}
    end

    {:noreply, spider}
  end

  @doc """
  Called when a scrape request is completed.

  When a request is completed, i.e. receives the response, and parsed, 
  this process receives a message with the result.

  If this is for the last request, it sets a new timer if needed.
  """
  def handle_info({ref, {:ok, %Request{}=req}}, spider) do
    data = Request.await(req)
    handle_info({ref, {:ok, data}}, spider)
  end

  def handle_info({ref, {:ok, requests = [%Request{} | _]}}, spider) do
    data = Stream.map(requests, &Request.await(&1))
    |> Enum.concat
    handle_info({ref, {:ok, data}}, spider)
  end

  def handle_info({ref, {:ok, data}}, spider) do
    # Remove this request from the list.
    {request, requests} = spider.requests
    |> Enum.reduce({nil, []}, fn(request, {req, requests}) ->
      case request.ref === ref do
        true -> {request, requests}
        false -> {req, requests ++ [request]}
      end
    end)
    spider = %{spider | requests: requests}

    url = request.url
    Logger.debug "Got data from #{url}"

    new_data = List.keystore(spider.data, url, 0, {url, data})
    interval = spider.options[:interval]
    spider = case length(requests) === 0 do
      true ->
        # Start a new crawl.
        :erlang.cancel_timer(spider.timer)
        timer = send_after(self, interval, :crawl)
        %{spider | timer: timer}
      false -> spider
    end

    {:noreply, %{spider | data: new_data}}
  end

  # Return value from `parse` callback
  def handle_info({_ref, {:stop, reason}}, spider) do
    Logger.info "Spider is stopped with reason #{reason}"
    {:stop, :normal, spider}
  end

  # The URL is 404, we remove it from the list to prevent requesting it
  # the next time, and call `handle_info` with empty data so it can
  # continue the loop.
  def handle_info({ref, {:error, {:not_found, url}}}, spider) do
    Logger.error("Failed to request to #{url} with 404 error")

    options = spider.options
    urls = Enum.filter(options.urls, &(&1 !== url))
    options = Keyword.put(options, :urls, urls)
    handle_info({ref, {:ok, []}}, %{spider| options: options})
  end

  def handle_info({ref, {:error, reason}}, spider) do
    # Retry with backoff?
    request = spider.requests
    |> Enum.find(%Request{}, &(&1.ref === ref))

    Logger.error("Failed to request to #{request.url} with reason #{reason}")
    # Return an empty data, and let the spider tries again next time.
    handle_info({ref, {:ok, []}}, spider)
  end

  def handle_info(_info, state) do
    {:noreply, state}
  end

  defp send_after(_dest, nil, _message) do
    :erlang.make_ref()
  end
  defp send_after(dest, time, message) do
    :erlang.send_after(time, dest, message)
  end

  defp call(method, %GenSpider{}=spider, args \\ nil) when is_atom(method) do
    Kernel.apply(spider.module, method, args || [spider.state])
  end
end
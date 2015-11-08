defmodule Scrapex.GenSpiderTest do
  use ExUnit.Case
  alias Scrapex.GenSpider
  doctest GenSpider

  @example_com "http://localhost:9090/example.com.html"
  @ecommerce_site "http://localhost:9090/e-commerce/static/index.html"
  @opts [urls: [@example_com]]

  test "a spider is a process" do
    defmodule GoodSpider do
      use GenSpider
      # GenSpider callbacks
      def init(args) do
        {:ok, args}
      end
    end

    {:ok, pid} = GenSpider.start_link(GoodSpider, [])
    assert is_pid(pid)

    {:ok, pid} = GenSpider.start(GoodSpider, [])
    assert is_pid(pid)
  end

  test "spider is based on GenServer" do
    defmodule EmoSpider do
      # GenSpider callbacks
      def init(_args) do
        :ignore
      end
    end

    defmodule BadSpider do
      # GenSpider callbacks
      def init(_args) do
        {:stop, :stop}
      end
    end

    assert :ignore == GenSpider.start(EmoSpider, [])
    assert {:error, :stop} == GenSpider.start(BadSpider, [])
  end

  test "default spider" do
    defmodule DoNothingSpider do
      use GenSpider
    end
    {:ok, pid} = GenSpider.start(DoNothingSpider, [])
    assert is_pid(pid)
  end

  test "should start the crawling immediately" do
    defmodule TestSpider do
      use GenSpider

      def init(tester) do
        {:ok, tester}
      end

      def start_requests(_urls, tester) do
        send tester, :start_requests
        {:ok, [], tester}
      end
      
    end

    GenSpider.start(TestSpider, self, @opts)

    assert_receive(:start_requests, 500)
  end

  test "should get the HTML of the start URL(s)" do
    defmodule HTMLSpider do
      use GenSpider

      def init(tester) do
        {:ok, tester}
      end

      def start_requests(urls, tester) do
        requests = urls
        |> Enum.map(&make_requests_from_url(&1, tester))
        {:ok, requests, tester}
      end

      defp make_requests_from_url(url, tester) do
        GenSpider.request(url, fn(response) -> 
          send tester, {:test_result, response.body}
        end)
      end
      
    end
    GenSpider.start(HTMLSpider, self, @opts)

    assert_receive({:test_result, actual}, 500)
    expected = HTTPoison.get!("http://localhost:9090/example.com.html").body
    assert actual === expected
  end

  test "can export data" do
    defmodule FastSpider do
      use GenSpider

      def start_requests(urls, tester) do
        requests = urls
        |> Enum.map(&make_requests_from_url(&1, tester))
        {:ok, requests, tester}
      end

      defp make_requests_from_url(url, tester) do
        GenSpider.request(url, fn(response) ->
          send tester, {:test_result, response.body}
          parse(response)
        end)
      end
      
    end
    {:ok, spider} = GenSpider.start(FastSpider, self, @opts)

    assert_receive({:test_result, _}, 5000)
    # Assume that the spider, which requested to the same URL, should
    # have finished before our request below.
    expected = HTTPoison.get!("http://localhost:9090/example.com.html").body
    assert [expected] == GenSpider.export(spider)

  end

  defmodule Spider do
    use GenSpider

    def start_requests(urls, tester) do
      requests = urls
      |> Enum.map(&make_requests_from_url(&1, tester))
      {:ok, requests, tester}
    end

    defp make_requests_from_url(url, tester) do
      GenSpider.request(url, fn(response) ->
        data = parse(response)
        send tester, {:test_result, response.body}
        data
      end)
    end

    def parse(response) do
      uuid = :crypto.strong_rand_bytes(8) |> Base.encode16
      {:ok, [uuid <> response.body]}
    end
    
  end

  test "can run on schedule" do
    opts = [urls: @opts[:urls], interval: 500]
    GenSpider.start(Spider, self, opts)

    assert_receive({:test_result, _}, 300)
    # Give time for spider to crawl
    :timer.sleep(50)
    assert_receive({:test_result, _}, 500)
  end

  test "new data will replace old data" do
    opts = [urls: @opts[:urls], interval: 500]
    {:ok, spider} = GenSpider.start(Spider, self, opts)

    assert_receive({:test_result, _old}, 300)
    [old] = GenSpider.export(spider)
    <<old_uuid :: 128, _rest :: binary>> = old
    # Give time for spider to crawl
    :timer.sleep(50)
    assert_receive({:test_result, _new}, 500)
    [new] = GenSpider.export(spider)
    <<new_uuid :: 128, _rest :: binary>> = new
    assert new_uuid !== old_uuid
  end

  test "multiple URLs should replace old data with merged new data" do
    opts = [urls: [ @ecommerce_site | @opts[:urls] ], interval: 500]
    {:ok, spider} = GenSpider.start(Spider, self, opts)

    assert_receive({:test_result, _old}, 1500)
    assert_receive({:test_result, _old}, 1500)

    old = GenSpider.export(spider)

    assert_receive({:test_result, _new}, 1500)
    assert_receive({:test_result, _new}, 1500)

    GenSpider.export(spider)
    |> Enum.with_index
    |> Enum.each(fn({data, index}) ->
      <<old_uuid :: 128, _rest :: binary>> = Enum.at(old, index)
      <<new_uuid :: 128, _rest :: binary>> = data
      assert new_uuid !== old_uuid
    end)
  end

  defmodule MapSpider do
    use GenSpider

    def start_requests(urls, tester) do
      requests = urls
      |> Enum.map(&make_requests_from_url(&1, tester))
      {:ok, requests, tester}
    end

    defp make_requests_from_url(url, tester) do
      spider = self()
      GenSpider.request(url, fn(response) ->
        {:ok, result} = parse(response)
        case tester.(result, spider) do
          {:stop, reason} ->
            {:stop, reason}
          {:test_result, result} ->
            {:ok, result}
        end
      end)
    end

    def parse(response) do
      result = [%{"body" => response.body}]
      {:ok, result}
    end
    
  end

  test "returned map can be exported to json" do
    tester = self
    callback = fn(result, _) ->
      send(tester, {:test_result, result})
    end
    {:ok, spider} = GenSpider.start(MapSpider, callback, @opts)

    assert_receive({:test_result, result}, 300)
    json = GenSpider.export(spider, :json)
    assert is_binary(json)
    assert json == Poison.encode!(result)
  end

  test "can export using an encoder" do
    tester = self
    callback = fn(result, _) ->
      send(tester, {:test_result, result})
    end
    {:ok, spider} = GenSpider.start(MapSpider, callback, @opts)

    assert_receive({:test_result, result}, 300)
    json = GenSpider.export(spider, &Poison.encode!/1)
    assert is_binary(json)
    assert json == Poison.encode!(result)
  end

  test "will await for data to export" do
    tester = self
    callback = fn(result, _) ->
      send(tester, {:test_result, result})
    end
    opts = [urls: [ @ecommerce_site | @opts[:urls] ]]
    {:ok, spider} = GenSpider.start(MapSpider, callback, opts)

    # Since we can export immediately after starting the spider, it
    # will need to await for data.
    data = GenSpider.export(spider)

    actual =
    opts[:urls]
    |> Enum.map(&(%{"body" => HTTPoison.get!(&1).body}))
    assert actual === data
  end

  test "will export partial or no data if spider returns stop" do
    tester = self
    first_response = HTTPoison.get!(@ecommerce_site).body
    callback = fn(result = [%{"body" => response}], _) ->
      case response do
        ^first_response ->
          send tester, {:test_result, result}
        _ ->
          {:stop, :test}
      end
    end

    opts = [urls: [ @ecommerce_site | @opts[:urls] ]]
    {:ok, spider} = GenSpider.start(MapSpider, callback, opts)

    data = GenSpider.export(spider)
    assert [%{"body" => first_response}] === data
  end

  test "stop the spider when the callback returns stop" do
    tester = self
    first_response = HTTPoison.get!(@ecommerce_site).body
    callback = fn(result = [%{"body" => response}], _) ->
      case response do
        ^first_response ->
          send tester, {:test_result, result}
        _ ->
          {:stop, :test}
      end
    end

    opts = [urls: [ @ecommerce_site | @opts[:urls] ]]
    {:ok, spider} = GenSpider.start(MapSpider, callback, opts)

    _data = GenSpider.export(spider)
    # Let the spider stop
    :timer.sleep(100)
    refute Process.alive?(spider)
  end

  test "can request fresh data regardless of timer" do
    opts = [urls: @opts[:urls], interval: 60000]
    {:ok, spider} = GenSpider.start(Spider, self, opts)
    # First export is always fresh, and same as next export.
    [old] = GenSpider.export(spider)
    assert [old] === GenSpider.export(spider)
    <<old_uuid :: 128, _rest :: binary>> = old

    [new] = GenSpider.export(spider, nil, true)
    <<new_uuid :: 128, _rest :: binary>> = new
    assert new_uuid !== old_uuid
  end

  test "can request for links during parsing" do
    # Instead of returning the parsed data, `parse` function
    # can return an async task, which will be awaited and merge
    # to the data.

    # Since this test is made without knowledge of selector engine,
    # we simply request other URL and return that body instead.
    callback = fn(_, _) ->
      # The final callback will send test result to this test proces,
      # but also return that tuple, which is what `GenSpider.await/1`
      # returns.
      # `GenSpider.request/2` returns an asynchronous task.
      request = GenSpider.request(@ecommerce_site, fn
        (response) -> {:test_result, [response.body]}
      end)
      # That task can be awaited.
      {:test_result, body} = GenSpider.await(request)
      {:test_result, body}
    end

    {:ok, spider} = GenSpider.start(MapSpider, callback, @opts)
    [data] = GenSpider.export(spider)
    assert data === HTTPoison.get!(@ecommerce_site).body
  end

  test "parse function can return an async request" do
    callback = fn(_what, spider) ->
      request = GenSpider.request(@ecommerce_site, fn
        (response) -> [response.body]
      end, spider)
      {:test_result, request}
    end

    {:ok, spider} = GenSpider.start(MapSpider, callback, @opts)
    [data] = GenSpider.export(spider)
    assert data === HTTPoison.get!(@ecommerce_site).body
  end

  test "parse function can return multiple async requests" do
    # Can be used to follow multiple links on a page.
    # Results will be concatenated.
    urls = [ @ecommerce_site | @opts[:urls] ]

    callback = fn(_, spider) ->
      requests =
      urls
      |> Enum.map(fn(url) ->
        GenSpider.request(url, fn
          (response) -> [response.body]
        end, spider)
      end)
      {:test_result, requests}
    end

    {:ok, spider} = GenSpider.start(MapSpider, callback, @opts)
    data = GenSpider.export(spider)

    actual =
    urls
    |> Enum.map(&(HTTPoison.get!(&1).body))

    assert data === actual
  end

  test "should follow redirect" do
    url = "http://localhost:9090/e-commerce/static"
    opts = [urls: [url]]
    tester = self
    callback = fn(result, _) ->
      send(tester, {:test_result, result})
    end

    {:ok, spider} = GenSpider.start(MapSpider, callback, opts)
    [%{"body" => data}] = GenSpider.export(spider)

    assert data === HTTPoison.get!(url <> "/index.html").body
  end
end

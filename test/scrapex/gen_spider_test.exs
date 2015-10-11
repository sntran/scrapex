defmodule Scrapex.GenSpiderTest do
  use ExUnit.Case
  alias Scrapex.GenSpider

  @example_com "http://localhost:9090/example.com.html"
  @ecommerce_site "http://localhost:9090/e-commerce/static/index.html"
  @opts [urls: [@example_com]]

  test "a spider is a process" do
    defmodule GoodSpider do
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

      def parse(response, tester) do
        send tester, {:test_result, response}
        {:ok, response, tester}
      end
      
    end

    GenSpider.start(TestSpider, self, @opts)

    assert_receive({:test_result, _}, 500)
  end

  test "should get the HTML of the start URL(s)" do
    defmodule HTMLSpider do
      use GenSpider

      def init(tester) do
        {:ok, tester}
      end

      def parse(response, tester) do
        send tester, {:test_result, response}
        {:ok, response, tester}
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

      def init(tester) do
        {:ok, tester}
      end

      def parse(response, tester) do
        send tester, {:test_result, response}
        {:ok, [response], tester}
      end
      
    end
    {:ok, spider} = GenSpider.start(FastSpider, self, @opts)

    assert_receive({:test_result, _}, 500)
    # Assume that the spider, which requested to the same URL, should
    # have finished before our request below.
    expected = HTTPoison.get!("http://localhost:9090/example.com.html").body
    assert [expected] == GenSpider.export(spider)

  end

  defmodule Spider do
    use GenSpider

    def init(tester) do
      {:ok, tester}
    end

    def parse(response, tester) do
      send tester, {:test_result, response}
      uuid = :crypto.strong_rand_bytes(8) |> Base.encode16
      {:ok, [uuid <> response], tester}
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

    def init(tester) do
      {:ok, tester}
    end

    def parse(response, tester) do
      result = [%{"body" => response}]
      case tester.(result) do
        {:stop, reason} ->
          {:stop, reason, tester}
        _ -> 
        {:ok, result, tester}
      end
    end
    
  end

  test "returned map can be exported to json" do
    tester = self
    callback = fn(result) -> send tester, {:test_result, result} end
    {:ok, spider} = GenSpider.start(MapSpider, callback, @opts)
    assert_receive({:test_result, result}, 300)
    json = GenSpider.export(spider, :json)
    assert is_binary(json)
    assert json == Poison.encode!(result)
  end

  test "can export using an encoder" do
    tester = self
    callback = fn(result) -> send tester, {:test_result, result} end
    {:ok, spider} = GenSpider.start(MapSpider, callback, @opts)
    assert_receive({:test_result, result}, 300)
    json = GenSpider.export(spider, &Poison.encode!/1)
    assert is_binary(json)
    assert json == Poison.encode!(result)
  end

  test "will await for data to export" do
    tester = self
    callback = fn(result) -> send tester, {:test_result, result} end
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
    callback = fn(result = [%{"body" => response}]) ->
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
    callback = fn(result = [%{"body" => response}]) ->
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
    # Let the spider stop
    :timer.sleep(100)
    refute Process.alive?(spider)
  end
end

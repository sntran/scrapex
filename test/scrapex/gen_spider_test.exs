defmodule Scrapex.GenSpiderTest do
  use ExUnit.Case
  alias Scrapex.GenSpider

  @example_com "http://localhost:9090/example.com.html"
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
        {:ok, response, tester}
      end
      
    end
    {:ok, spider} = GenSpider.start(FastSpider, self, @opts)

    assert_receive({:test_result, _}, 500)
    # Assume that the spider, which requested to the same URL, should
    # have finished before our request below.
    expected = HTTPoison.get!("http://localhost:9090/example.com.html").body
    assert [expected] == GenSpider.export(spider)

  end

  test "can run on schedule" do
    defmodule ScheduleSpider do
      use GenSpider

      def init(tester) do
        {:ok, tester}
      end

      def parse(response, tester) do
        send tester, {:test_result, response}
        {:ok, response, tester}
      end
      
    end
    opts = [urls: @opts[:urls], interval: 500]
    GenSpider.start(ScheduleSpider, self, opts)

    assert_receive({:test_result, _}, 300)
    :timer.sleep(100)
    assert_receive({:test_result, _}, 500)
  end
end

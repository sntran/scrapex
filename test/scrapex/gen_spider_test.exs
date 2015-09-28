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

      def parse(_, state) do
        # Assert that this function is called.
        assert state
        {:ok, state}
      end
      
    end

    GenSpider.start(TestSpider, [], @opts)
  end

  defmodule Spider do
    use GenSpider

    def parse(_response, state) do
      # Assert that this function is called.
      assert state
      {:ok, state}
    end
    
  end

  test "should get the HTML of the start URL(s)" do
    defmodule HTMLSpider do
      use GenSpider

      def parse(actual, state) do
        expected = HTTPoison.get!("http://localhost:9090/example.com.html").body
        assert actual === expected
        {:ok, state}
      end
      
    end
    GenSpider.start(HTMLSpider, [], @opts)
  end
end

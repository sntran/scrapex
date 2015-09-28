defmodule Scrapex.GenSpiderTest do
  use ExUnit.Case, async: true
  alias Scrapex.GenSpider

  test "a spider is a process" do
    defmodule GoodSpider do
      # GenSpider callbacks
      def init(args) do
        {:ok, args}
      end

      def parse(_, state) do
        {:ok, state}
      end
    end

    {:ok, pid} = GenSpider.start_link(GoodSpider, [])
    assert is_pid(pid)

    {:ok, pid} = GenSpider.start(GoodSpider, [])
    assert is_pid(pid)
  end

  test "spider is based on GenServer" do
    stop_reason = :stop
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

    GenSpider.start(TestSpider, [])
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
    GenSpider.start(Spider, [], [urls: ["http://www.example.com"]])
  end
end

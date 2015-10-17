defmodule Scrapex.Spider.ExampleTest do
  use ExUnit.Case

  alias Spider.Example
  import Scrapex.Selector

  defmodule Example do
    alias Scrapex.GenSpider
    use GenSpider

    # Client
    def start_link(parser) do
      opts =  [
          urls: ["http://localhost:9090/e-commerce/static/index.html"]]
      GenSpider.start_link(__MODULE__, parser, opts)
    end

    def export(spider) do
      GenSpider.export(spider)
    end

    # Server (callbacks)

    def init(parser) do
      {:ok, parser}
    end
    
    def parse(response, parser) do
      results = parser.(response)
      {:ok, results, parser}
    end
  end

  def parse_product(html) do
    html 
    |> select(".thumbnail")
    |> Enum.map(fn(selector) ->
      [name] = selector |> select(".title") |> extract
      [description] = selector |> select(".description") |> extract
      [price] = selector |> select(".price") |> extract

      %{"name" => name, "description" => description, "price" => price}
    end)
  end

  test "get data on page" do
    {:ok, spider} = Example.start_link(&parse_product/1)
    results = Example.export(spider)
    assert length(results) === 3
  end
end
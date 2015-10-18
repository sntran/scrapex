defmodule Scrapex.Spider.ExampleTest do
  use ExUnit.Case

  alias Scrapex.GenSpider
  alias Spider.Example
  import Scrapex.Selector

  defmodule Example do
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

  def parse_product(response) do
    response.body 
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

  test "can follow links" do
    parser = fn(response) ->
      response.body 
      |> select("#side-menu .category-link")
      |> Enum.flat_map(fn(anchor) ->
        [href] = anchor |> extract("href")
        full_url = GenSpider.Response.url_join(response, href) <> "/index.html"
        [category] = anchor |> extract()

        GenSpider.request(full_url, fn({:ok, response}) ->
          parse_product(response)
        end)
        |> GenSpider.await()
        |> Enum.map(&Map.put(&1, "category", category))
      end)
    end

    {:ok, spider} = Example.start_link(parser)
    results = Example.export(spider)
    assert length(results) === 6
  end
end
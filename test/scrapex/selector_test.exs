defmodule Scrapex.SelectorTest do
  use ExUnit.Case, async: true
  import Scrapex.Selector

  setup_all do
    url = "http://localhost:9090/e-commerce/static/index.html"
    html = HTTPoison.get!(url).body

    # No metadata
    {:ok, url: url, body: html}
  end

  test "parse CSS selector", context do
    [href] = context.body
    |> select("a.navbar-brand")
    |> extract("href")

    assert href === "/"
  end

  test "select text content", context do
    [h1] = context.body
    |> select("h1")
    |> extract("text")

    assert h1 === "E-commerce training site"
  end

  test "default to get content", context do
    [h1] = context.body
    |> select("h1")
    |> extract()

    assert h1 === "E-commerce training site"
  end

  test "select text content and children content", context do
    link_texts = context.body
    |> select("a.category-link")
    |> extract()

    assert link_texts === ["Computers", "Phones"]
  end

  test "trip all Unicode whitespaces", context do
    [p] = context.body
    |> select(".jumbotron p")
    |> extract()

    assert p === "Welcome to WebScraper e-commerce site. You can use this site for training to learn how to use the Web Scraper. Items listed here are not for sale."
  end

  # TESTS FOR ENUMERABLE

  test "can be enumerable", context do
    selectors = select(context.body, "a.category-link")
    # Of course you can enumarate extracted values
    categories = extract(selectors)
    |> Enum.map(&(&1))

    assert categories == Enum.map(selectors, fn(selector) ->
      [value] = extract(selector)
      value
    end)
  end

  test "a single selector can still be enumerable", context do
    selectors = select(context.body, "a.category-link")
    # Of course you can enumarate extracted values
    categories = extract(selectors)
    |> Enum.map(&(&1))

    selectors = select(context.body, "h1")
    expected = ["E-commerce training site"]

    assert expected == Enum.map(selectors, fn(selector) ->
      [value] = extract(selector)
      value
    end)
  end
end
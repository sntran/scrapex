defmodule Scrapex.SelectorTest do
  use ExUnit.Case, async: true
  import Scrapex.Selector

  setup_all do
    url = "http://localhost:9090/example.com.html"
    html = HTTPoison.get!(url).body

    # No metadata
    {:ok, url: url, body: html}
  end

  test "parse CSS selector", context do
    [href] = context.body
    |> select("a[href^=http]")
    |> extract("href")

    assert href === "http://www.iana.org/domains/example"
  end

  test "select text content", context do
    [h1] = context.body
    |> select("h1")
    |> extract("text")

    assert h1 === "Example Domain"
  end

  test "default to get content", context do
    [h1] = context.body
    |> select("h1")
    |> extract()

    assert h1 === "Example Domain"
  end

  test "select text content and children content", context do
    [link_text] = context.body
    |> select("p ~ p")
    |> extract()

    assert link_text === "More information..."
  end
end
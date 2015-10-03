defmodule Scrapex.SelectorTest do
  use ExUnit.Case
  alias Scrapex.Selector

  test "parse CSS selector" do
    href = HTTPoison.get!("http://localhost:9090/example.com.html").body
    |> Selector.select("a[href^=http]")
    |> Selector.extract("href")

    assert href === ["http://www.iana.org/domains/example"]
  end

  test "get text content" do
    href = HTTPoison.get!("http://localhost:9090/example.com.html").body
    |> Selector.select("h1")
    |> Selector.extract("text")

    assert href === ["Example Domain"]
  end
end
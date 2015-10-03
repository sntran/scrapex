defmodule Scrapex.SelectorTest do
  use ExUnit.Case
  alias Scrapex.Selector

  test "parse CSS selector" do
    href = HTTPoison.get!("http://localhost:9090/example.com.html").body
    |> Selector.css("a[href^=http]")
    |> Selector.attribute("href")

    assert href === ["http://www.iana.org/domains/example"]
  end
end
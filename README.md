Scrapex
=======

An open source and collaborative framework for extracting the data you need from websites. In a fast, simple, yet extensible way.

## Features

### Fast and powerful
Write the rules to extract the data and let Scrapex do the rest.

### Easily extensible
Extensible by design, plug new functionality easily without having to touch the core.

### Portable, Elixir
Written in Elixir and runs on Linux, Windows, Mac, BSD, and embedded devices.

## Build your own webcrawlers

    defmodule BlogSpider do
      use GenSpider

      @start_urls ["http://blog.scrapinghub.com"]
      
      def parse(response, %{"selectors" => selectors}) do
        response
        |> css("ul li a::attr(\"href\")")
        |> re(~r/.*/\d\d\d\d/\d\d/$/)
        |> Enum.map(fn(url) ->
          Scrapex.Request(urljoin(url), &parse_titles/1)
        end)
      end

      defp parse_titles(response) do
        response
        |> css("div.entries > ul > li a::text")
        |> extract()
        |> Enum.map(fn(post_title) -> %{"title" => post_title} end)
      end
    end

    # Start the spider
    opts = name: :webscrapper
    {:ok, pid} = GenSpider.start_link(BlogSpider, sitemap, opts)

    # This is the client
    GenSpider.export(pid, :json)
    #=> "[{} | _]"
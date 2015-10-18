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

    alias Scrapex.GenSpider
    defmodule StackOverflowSpider do
      use GenSpider
      import Scrapex.Selector
      
      def parse(response, state) do
        result = response.body
        |> select(".question-summary h3 a")
        |> extract("href")
        |> Enum.map(fn(href) ->
          GenSpider.Response.url_join(response, href)
          |> GenSpider.request(&parse_question/1)
          |> GenSpider.await
        end)
        {:ok, result, state}
      end
      
      defp parse_question({:ok, response}) do
        html = response.body
        [title] = html |> select("h1 a") |> extract()
        question = html |> select(".question")
        [body] = question |> select(".post-text") |> extract
        [votes] = question |> select(".vote-count-post") |> extract
        tags = question |> select(".post-tag") |> extract
        
        %{title: title, body: body, votes: votes, tags: tags}
      end
    end
    urls = ["http://stackoverflow.com/questions?sort=votes"]
    opts = [name: :webscrapper, urls: urls]
    {:ok, spider} = GenSpider.start_link(StackOverflowSpider, [], opts)
    questions = GenSpider.export(spider)
    #=> "[{} | _]"

## TODOS

- [x] `GenSpider behaviour`.
- [x] Request URL and pass response to `parse/2` callback.
- [x] One time spider
- [x] CSS selector
- [ ] XPath selector
- [x] Yield for requests in `parse/2`
- [ ] Parse response chunk by chunk
- [ ] CLI
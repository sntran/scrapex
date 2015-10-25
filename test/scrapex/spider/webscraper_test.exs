defmodule Scrapex.Spider.WebScraperTest do
  use ExUnit.Case

  alias Scrapex.Spider.WebScraper
  import Scrapex.Selector

  @url "http://localhost:9090/e-commerce/static/index.html"

  test "scrape single item" do
    selectors = [%{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => false,
      "id" => "Page Title",
      "selector" => ".jumbotron h1",
      "delay" => ""
    }]

    sitemap = %{"startUrl" => @url, "selectors" => selectors}

    {:ok, spider} = WebScraper.start_link(sitemap)
    [data] = WebScraper.export(spider)

    expected = %{
      "Page Title" => "E-commerce training site"
    }
    assert data === expected
  end

  test "scrape multiple single items" do
    selectors = [%{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => false,
      "id" => "Page Title",
      "selector" => ".jumbotron h1",
      "delay" => ""
    }, %{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => false,
      "id" => "Main Description",
      "selector" => ".jumbotron p",
      "delay" => ""
    }]

    sitemap = %{"startUrl" => @url, "selectors" => selectors}

    {:ok, spider} = WebScraper.start_link(sitemap)
    [data] = WebScraper.export(spider)

    expected = %{
      "Page Title" => "E-commerce training site",
      "Main Description" => "Welcome to WebScraper e-commerce site. You can use this site for training to learn how to use the Web Scraper. Items listed here are not for sale."
    }
    assert data === expected
  end

  test "scrape multiple items" do
    selectors = [%{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => true,
      "id" => "Category",
      "selector" => "a.category-link",
      "delay" => ""
    }]

    sitemap = %{"startUrl" => @url, "selectors" => selectors}

    {:ok, spider} = WebScraper.start_link(sitemap)
    data = WebScraper.export(spider)

    expected = [%{
      "Category" => "Computers"
    }, %{
      "Category" => "Phones"
    }]
    assert data === expected
  end

  test "scrape both single and multiple items" do
    selectors = [%{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => true,
      "id" => "Category",
      "selector" => "a.category-link",
      "delay" => ""
    }, %{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => false,
      "id" => "Page Title",
      "selector" => ".jumbotron h1",
      "delay" => ""
    }]

    sitemap = %{"startUrl" => @url, "selectors" => selectors}

    {:ok, spider} = WebScraper.start_link(sitemap)
    data = WebScraper.export(spider)

    expected = [%{
      "Category" => "Computers",
      "Page Title" => "E-commerce training site"
    }, %{
      "Category" => "Phones",
      "Page Title" => "E-commerce training site"
    }]
    assert data === expected
  end

  test "scrape with empty selector" do
    selectors = [%{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => true,
      "id" => "Category",
      "selector" => "a.category-link",
      "delay" => ""
    }, %{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => false,
      "id" => "Page Title",
      "selector" => ".jumbotron h2", # Intended typo.
      "delay" => ""
    }]

    sitemap = %{"startUrl" => @url, "selectors" => selectors}

    {:ok, spider} = WebScraper.start_link(sitemap)
    data = WebScraper.export(spider)

    expected = [%{
      "Category" => "Computers"
    }, %{
      "Category" => "Phones"
    }]
    assert data === expected

    selectors = [%{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => true,
      "id" => "Category",
      "selector" => "a.category", # Intended typo.
      "delay" => ""
    }, %{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => false,
      "id" => "Page Title",
      "selector" => ".jumbotron h1",
      "delay" => ""
    }]

    sitemap = %{"startUrl" => @url, "selectors" => selectors}

    {:ok, spider} = WebScraper.start_link(sitemap)
    data = WebScraper.export(spider)

    expected = [%{
      "Page Title" => "E-commerce training site"
    }]
    assert data === expected
  end

  test "scrape only one of multiple items" do
    selectors = [%{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => false, # We only want one category among 3
      "id" => "Category",
      "selector" => "a.category-link",
      "delay" => ""
    }, %{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => true, # Even though there is only 1 h1
      "id" => "Page Title",
      "selector" => ".jumbotron h1",
      "delay" => ""
    }]

    sitemap = %{"startUrl" => @url, "selectors" => selectors}

    {:ok, spider} = WebScraper.start_link(sitemap)
    data = WebScraper.export(spider)

    expected = [%{
      "Category" => "Computers",
      "Page Title" => "E-commerce training site"
    }]
    assert data === expected

    # Test group of multiple items
    selectors = [%{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => true,
      "id" => "Category",
      "selector" => "a.category-link",
      "delay" => ""
    }, %{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => false,
      "id" => "Navigation", # We only want one category among 3
      "selector" => ".navbar-right a",
      "delay" => ""
    }]

    sitemap = %{"startUrl" => @url, "selectors" => selectors}

    {:ok, spider} = WebScraper.start_link(sitemap)
    data = WebScraper.export(spider)

    expected = [%{
      "Category" => "Computers",
      "Navigation" => "Download"
    }, %{
      "Category" => "Phones",
      "Navigation" => "Download"
    }]
    assert data === expected
  end

  test "scrape mixed between single and multiple, sorted" do
    selectors = [%{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => true,
      "id" => "Category",
      "selector" => "a.category-link ",
      "delay" => ""
    }, %{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => false,
      "id" => "Page Title",
      "selector" => ".jumbotron h1",
      "delay" => ""
    }, %{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => true,
      "id" => "Navigation",
      "selector" => ".navbar-right a",
      "delay" => ""
    }]

    sitemap = %{"startUrl" => @url, "selectors" => selectors}

    {:ok, spider} = WebScraper.start_link(sitemap)
    data = WebScraper.export(spider)

    expected = [%{
      "Category" => "Computers", 
      "Page Title" => "E-commerce training site", 
      "Navigation" => "Download"
    }, %{
      "Category" => "Phones", 
      "Page Title" => "E-commerce training site", 
      "Navigation" => "Download"
    }, %{
      "Category" => "Computers", 
      "Page Title" => "E-commerce training site", 
      "Navigation" => "GitHub"
    }, %{
      "Category" => "Phones", 
      "Page Title" => "E-commerce training site", 
      "Navigation" => "GitHub"
    }, %{
      "Category" => "Computers", 
      "Page Title" => "E-commerce training site", 
      "Navigation" => "Donate"
    }, %{
      "Category" => "Phones", 
      "Page Title" => "E-commerce training site", 
      "Navigation" => "Donate"
    }]
    assert data === expected
  end
end
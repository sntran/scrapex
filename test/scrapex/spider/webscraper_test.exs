defmodule Scrapex.Spider.WebScraperTest do
  use ExUnit.Case

  alias Scrapex.Spider.WebScraper

  @url "http://localhost:9090/e-commerce/static/index.html"
  @page_title "E-commerce training site"
  @description "Welcome to WebScraper e-commerce site. You can use this site for training to learn how to use the Web Scraper. Items listed here are not for sale."
  @categories ["Computers", "Phones"]
  @subcategories [["Laptops", "Tablets"], ["Phones"]]
  @home [23, 5, 39]
  @computers [21, 6, 8]
  @phones [32, 39, 11]

  setup_all do
    items =
    "test/scrapex/spider/webscraper.csv"
    |> File.stream!
    |> CSV.decode(headers: true)
    |> Enum.map(fn(row) ->
      row
      |> Map.delete("Category-href")
      |> Map.delete("SubCategory-href")
      |> Map.delete("Page-href")
    end)

    {:ok, items: items}
  end


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
      "Page Title" => @page_title,
      "Main Description" => @description
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
    assert ScrapexAsserter.array_equals(data, expected)
  end

  test "follow nodes under _root first" do
    selectors = [%{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => false,
      "id" => "Page Title",
      "selector" => ".jumbotron h1",
      "delay" => ""
    }, %{
      "parentSelectors" => ["Category"],
      "type" => "SelectorText",
      "multiple" => false,
      "id" => "SubCategory",
      "selector" => "a.subcategory-link",
      "delay" => ""
    }, %{
      "parentSelectors" => ["_root"],
      "type" => "SelectorLink",
      "multiple" => false,
      "id" => "Category",
      "selector" => "a.category-link",
      "delay" => ""
    }]
    sitemap = %{"startUrl" => @url, "selectors" => selectors}

    {:ok, spider} = WebScraper.start_link(sitemap)
    [data] = WebScraper.export(spider)

    expected = %{
      "Category" => "Computers",
      "Page Title" => "E-commerce training site",
      "SubCategory" => "Laptops"
    }
    assert data === expected
  end

  test "whether to retrieve multiple items from selector" do
    selectors = [%{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => false,
      "id" => "Page Title",
      "selector" => ".jumbotron h1",
      "delay" => ""
    }, %{
      "parentSelectors" => ["Category"],
      "type" => "SelectorText",
      "multiple" => true,
      "id" => "SubCategory",
      "selector" => "a.subcategory-link",
      "delay" => ""
    }, %{
      "parentSelectors" => ["_root"],
      "type" => "SelectorLink",
      "multiple" => true,
      "id" => "Category",
      "selector" => "a.category-link",
      "delay" => ""
    }]
    sitemap = %{"startUrl" => @url, "selectors" => selectors}

    {:ok, spider} = WebScraper.start_link(sitemap)
    data = WebScraper.export(spider)

    # There are 2 categories, and 3 subcategories total, so there
    # must be 3 results.

    assert length(data) === 3
    expected = [%{
      "Category" => "Computers",
      "Page Title" => "E-commerce training site",
      "SubCategory" => "Laptops"
    }, %{
      "Category" => "Computers",
      "Page Title" => "E-commerce training site",
      "SubCategory" => "Tablets"
    }, %{
      "Category" => "Phones",
      "Page Title" => "E-commerce training site",
      "SubCategory" => "Touch"
    }]

    assert data === expected
  end

  test "more level of selectors" do
    selectors = [%{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => false,
      "id" => "Page Title",
      "selector" => ".jumbotron h1",
      "delay" => ""
    }, %{
      "parentSelectors" => ["Category"],
      "type" => "SelectorLink",
      "multiple" => true,
      "id" => "SubCategory",
      "selector" => "a.subcategory-link",
      "delay" => ""
    }, %{
      "parentSelectors" => ["_root"],
      "type" => "SelectorLink",
      "multiple" => true,
      "id" => "Category",
      "selector" => "a.category-link",
      "delay" => ""
    }, %{
      "parentSelectors" => ["SubCategory"],
      "type" => "SelectorText",
      "multiple" => true,
      "id" => "Name",
      "selector" => "a.title",
      "delay" => ""
    }]

    sitemap = %{"startUrl" => @url, "selectors" => selectors}

    {:ok, spider} = WebScraper.start_link(sitemap)
    data = WebScraper.export(spider)

    # There are 2 categories, and 3 subcategories total, each has 6 
    # items, for a total of 18 items.

    assert length(data) === 18
  end

  test "parse level with no child" do
    selectors = [%{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => false,
      "id" => "Page Title",
      "selector" => ".jumbotron h1",
      "delay" => ""
    }, %{
      "parentSelectors" => ["_root"],
      "type" => "SelectorLink",
      "multiple" => true,
      "id" => "Category",
      "selector" => "a.category-link",
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

  test "don't put element from SelectorElement in result" do
    selectors = [%{
      "parentSelectors" => ["_root"],
      "type" => "SelectorText",
      "multiple" => false,
      "id" => "Page Title",
      "selector" => ".jumbotron h1",
      "delay" => ""
    }, %{
      "parentSelectors" => ["Category"],
      "type" => "SelectorText",
      "multiple" => true,
      "id" => "SubCategory",
      "selector" => "a.subcategory-link",
      "delay" => ""
    }, %{
      "parentSelectors" => ["_root"],
      "type" => "SelectorLink",
      "multiple" => true,
      "id" => "Category",
      "selector" => "a.category-link",
      "delay" => ""
    }, %{
      "parentSelectors" => ["Category"],
      "type" => "SelectorElement",
      "multiple" => true,
      "id" => "Item",
      "selector" => "div.thumbnail",
      "delay" => ""
    }]
    sitemap = %{"startUrl" => @url, "selectors" => selectors}

    {:ok, spider} = WebScraper.start_link(sitemap)
    data = WebScraper.export(spider)

    # There are 2 categories, and 3 subcategories total, so there
    # must be 3 results.

    assert length(data) === 3
    expected = [%{
      "Category" => "Computers",
      "Page Title" => "E-commerce training site",
      "SubCategory" => "Laptops"
    }, %{
      "Category" => "Computers",
      "Page Title" => "E-commerce training site",
      "SubCategory" => "Tablets"
    }, %{
      "Category" => "Phones",
      "Page Title" => "E-commerce training site",
      "SubCategory" => "Touch"
    }]

    assert data === expected
  end

  test "can group selectors with SelectorElement", context do
    selectors = [%{
      "parentSelectors" => ["_root"],
      "type" => "SelectorLink",
      "multiple" => true,
      "id" => "Category",
      "selector" => "a.category-link",
      "delay" => ""
    }, %{
      "parentSelectors" => ["Category"],
      "type" => "SelectorElement",
      "multiple" => true,
      "id" => "Item",
      "selector" => "div.thumbnail",
      "delay" => ""
    }, %{
      "parentSelectors" => ["Item"],
      "type" => "SelectorText",
      "multiple" => false,
      "id" => "Name",
      "selector" => "a.title",
      "regex" => "",
      "delay" => ""
    }, %{
      "parentSelectors" => ["Item"],
      "type" => "SelectorText",
      "multiple" => false,
      "id" => "Price",
      "selector" => "h4.pull-right",
      "regex" => "",
      "delay" => ""
    }, %{
      "parentSelectors" => ["Item"],
      "type" => "SelectorText",
      "multiple" => false,
      "id" => "Description",
      "selector" => "p.description",
      "regex" => "",
      "delay" => ""
    }]
    sitemap = %{"startUrl" => @url, "selectors" => selectors}

    {:ok, spider} = WebScraper.start_link(sitemap)
    data = WebScraper.export(spider)

    # There are 2 categories. Each categories has
    # 3 products on display. Total 2 x 3 = 9 items.

    assert length(data) === 6
    items = context.items

    Enum.concat([@computers, @phones])
    |> Enum.map(&Enum.at(items, &1))
    |> Enum.map(fn(item) ->
      item
      |> Map.delete("Page")
      |> Map.delete("SubCategory")
    end)
    |> ScrapexAsserter.array_equals(data)
    |> assert
  end
end
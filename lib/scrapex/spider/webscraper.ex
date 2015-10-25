defmodule Scrapex.Spider.WebScraper do
  @moduledoc ~S"""
  A spider using "sitemap" configuration from WebScraper.IO

  WebScraper.IO provides a Chrome extension to visually define scraping
  rules. This module provides a spider to use those rules to collect
  data.

  ## Examples

  Here is an example of scraping the E-commerce training site at
  http://webscraper.io/test-sites/e-commerce/static, following the
  instructions in WebScraper's tutorials section.

      iex> sitemap = %{
      ...> "_id" => "webscrapper",
      ...> "startUrl" => "http://webscraper.io/test-sites/e-commerce/static",
      ...> "selectors" => [{
      ...>     "parentSelectors" => ["_root"],
      ...>     "type" => "SelectorLink",
      ...>     "multiple" => true,
      ...>     "id" => "Category",
      ...>     "selector" => "a.category-link",
      ...>     "delay" => ""
      ...>   }, {
      ...>     "parentSelectors" => ["Item"],
      ...>     "type" => "SelectorText",
      ...>     "multiple" => false,
      ...>     "id" => "Name",
      ...>     "selector" => "a.title",
      ...>     "regex" => "",
      ...>     "delay" => ""
      ...>   }, {
      ...>     "parentSelectors" => ["Item"],
      ...>     "type" => "SelectorText",
      ...>     "multiple" => false,
      ...>     "id" => "Price",
      ...>     "selector" => "h4.pull-right",
      ...>     "regex" => "",
      ...>     "delay" => ""
      ...>   }, {
      ...>     "parentSelectors" => ["Item"],
      ...>     "type" => "SelectorText",
      ...>     "multiple" => false,
      ...>     "id" => "Description",
      ...>     "selector" => "p.description",
      ...>     "regex" => "",
      ...>     "delay" => ""
      ...>   }, {
      ...>     "parentSelectors" => ["Category"],
      ...>     "type" => "SelectorLink",
      ...>     "multiple" => true,
      ...>     "id" => "SubCategory",
      ...>     "selector" => "a.subcategory-link",
      ...>     "delay" => ""
      ...>   }, {
      ...>     "parentSelectors" => ["SubCategory"],
      ...>     "type" => "SelectorElement",
      ...>     "multiple" => true,
      ...>     "id" => "Item",
      ...>     "selector" => "div.thumbnail",
      ...>     "delay" => ""
      ...>   }]
      ...> }
      iex> {:ok, spider} = WebScraper.start_link(sitemap)
      iex> data = WebScraper.export()
      [%{
        "Category" => "Computers",
        "Category-href" => "http://webscraper.io/test-sites/e-commerce/static/computers",
        "Name" => "Iconia B1-730HD",
        "Price" => "$99.99",
        "Description" => "Black, 7\", 1.6GHz Dual-Core, 8GB, Android 4.4",
        "SubCategory" => "Tablets",
        "SubCategory-href" => "http://webscraper.io/test-sites/e-commerce/static/computers/tablets"
      },%{
        "Category" => "Computers",
        "Category-href" => "http://webscraper.io/test-sites/e-commerce/static/computers",
        "Name" => "Pavilion",
        "Price" => "$609.99",
        "Description" => "15.6\", Core i5-4200U, 6GB, 750GB, Windows 8.1",
        "SubCategory" => "Laptops",
        "SubCategory-href" => "http://webscraper.io/test-sites/e-commerce/static/computers/laptops"
      },%{
        "Category" => "Phones",
        "Category-href" => "http://webscraper.io/test-sites/e-commerce/static/phones",
        "Name" => "Samsung Galaxy",
        "Price" => "$93.99",
        "Description" => "5 mpx. Android 5.0",
        "SubCategory" => "Touch",
        "SubCategory-href" => "http://webscraper.io/test-sites/e-commerce/static/phones/touch"
      },%{
        "Category" => "Phones",
        "Category-href" => "http://webscraper.io/test-sites/e-commerce/static/phones",
        "Name" => "Sony Xperia",
        "Price" => "$118.99",
        "Description" => "GPS, waterproof",
        "SubCategory" => "Touch",
        "SubCategory-href" => "http://webscraper.io/test-sites/e-commerce/static/phones/touch"
      },%{
        "Category" => "Computers",
        "Category-href" => "http://webscraper.io/test-sites/e-commerce/static/computers",
        "Name" => "Memo Pad HD 7",
        "Price" => "$101.99",
        "Description" => "IPS, Dual-Core 1.2GHz, 8GB, Android 4.3",
        "SubCategory" => "Tablets",
        "SubCategory-href" => "http://webscraper.io/test-sites/e-commerce/static/computers/tablets"
      },%{
        "Category" => "Computers",
        "Category-href" => "http://webscraper.io/test-sites/e-commerce/static/computers",
        "Name" => "Lenovo IdeaTab",
        "Price" => "$69.99",
        "Description" => "7\" screen, Android",
        "SubCategory" => "Tablets",
        "SubCategory-href" => "http://webscraper.io/test-sites/e-commerce/static/computers/tablets"
      },%{
        "Category" => "Phones",
        "Category-href" => "http://webscraper.io/test-sites/e-commerce/static/phones",
        "Name" => "Ubuntu Edge",
        "Price" => "$499.99",
        "Description" => "Sapphire glass",
        "SubCategory" => "Touch",
        "SubCategory-href" => "http://webscraper.io/test-sites/e-commerce/static/phones/touch"
      },%{
        "Category" => "Computers",
        "Category-href" => "http://webscraper.io/test-sites/e-commerce/static/computers",
        "Name" => "Acer Iconia",
        "Price" => "$96.99",
        "Description" => "7\" screen, Android, 16GB",
        "SubCategory" => "Tablets",
        "SubCategory-href" => "http://webscraper.io/test-sites/e-commerce/static/computers/tablets"
      },%{
        "Category" => "Computers",
        "Category-href" => "http://webscraper.io/test-sites/e-commerce/static/computers",
        "Name" => "Aspire E1-572G",
        "Price" => "$581.99",
        "Description" => "15.6\", Core i5-4200U, 8GB, 1TB, Radeon R7 M265, Windows 8.1",
        "SubCategory" => "Laptops",
        "SubCategory-href" => "http://webscraper.io/test-sites/e-commerce/static/computers/laptops"
      },%{
        "Category" => "Phones",
        "Category-href" => "http://webscraper.io/test-sites/e-commerce/static/phones",
        "Name" => "Nokia X",
        "Price" => "$109.99",
        "Description" => "Andoid, Jolla dualboot",
        "SubCategory" => "Touch",
        "SubCategory-href" => "http://webscraper.io/test-sites/e-commerce/static/phones/touch"
      },%{
        "Category" => "Phones",
        "Category-href" => "http://webscraper.io/test-sites/e-commerce/static/phones",
        "Name" => "LG Optimus",
        "Price" => "$57.99",
        "Description" => "3.2\" screen",
        "SubCategory" => "Touch",
        "SubCategory-href" => "http://webscraper.io/test-sites/e-commerce/static/phones/touch"
      },%{
        "Category" => "Computers",
        "Category-href" => "http://webscraper.io/test-sites/e-commerce/static/computers",
        "Name" => "IdeaTab A3500L",
        "Price" => "$88.99",
        "Description" => "Black, 7\" IPS, Quad-Core 1.2GHz, 8GB, Android 4.2",
        "SubCategory" => "Tablets",
        "SubCategory-href" => "http://webscraper.io/test-sites/e-commerce/static/computers/tablets"
      },%{
        "Category" => "Computers",
        "Category-href" => "http://webscraper.io/test-sites/e-commerce/static/computers",
        "Name" => "Galaxy Tab 3",
        "Price" => "$97.99",
        "Description" => "7\", 8GB, Wi-Fi, Android 4.2, White",
        "SubCategory" => "Tablets",
        "SubCategory-href" => "http://webscraper.io/test-sites/e-commerce/static/computers/tablets"
      },%{
        "Category" => "Computers",
        "Category-href" => "http://webscraper.io/test-sites/e-commerce/static/computers",
        "Name" => "HP 350 G1",
        "Price" => "$577.99",
        "Description" => "15.6\", Core i5-4200U, 4GB, 750GB, Radeon HD8670M 2GB, Windows",
        "SubCategory" => "Laptops",
        "SubCategory-href" => "http://webscraper.io/test-sites/e-commerce/static/computers/laptops"
      },%{
        "Category" => "Phones",
        "Category-href" => "http://webscraper.io/test-sites/e-commerce/static/phones",
        "Name" => "Nokia 123",
        "Price" => "$24.99",
        "Description" => "7 day battery",
        "SubCategory" => "Touch",
        "SubCategory-href" => "http://webscraper.io/test-sites/e-commerce/static/phones/touch"
      },%{
        "Category" => "Computers",
        "Category-href" => "http://webscraper.io/test-sites/e-commerce/static/computers",
        "Name" => "HP 250 G3",
        "Price" => "$520.99",
        "Description" => "15.6\", Core i5-4210U, 4GB, 500GB, Windows 8.1",
        "SubCategory" => "Laptops",
        "SubCategory-href" => "http://webscraper.io/test-sites/e-commerce/static/computers/laptops"
      },%{
        "Category" => "Computers",
        "Category-href" => "http://webscraper.io/test-sites/e-commerce/static/computers",
        "Name" => "Aspire E1-510",
        "Price" => "$306.99",
        "Description" => "15.6\", Pentium N3520 2.16GHz, 4GB, 500GB, Linux",
        "SubCategory" => "Laptops",
        "SubCategory-href" => "http://webscraper.io/test-sites/e-commerce/static/computers/laptops"
      },%{
        "Category" => "Computers",
        "Category-href" => "http://webscraper.io/test-sites/e-commerce/static/computers",
        "Name" => "Packard 255 G2",
        "Price" => "$416.99",
        "Description" => "15.6\", AMD E2-3800 1.3GHz, 4GB, 500GB, Windows 8.1",
        "SubCategory" => "Laptops",
        "SubCategory-href" => "http://webscraper.io/test-sites/e-commerce/static/computers/laptops"
      }]
  """

  @type item :: [ property ]
  @type property :: { key, value }
  @type key :: binary
  @type value :: binary

  alias Scrapex.GenSpider
  alias GenSpider.Response
  import Scrapex.Selector
  use GenSpider

  # Client
  def start_link(sitemap = %{"startUrl" => url}) when is_binary(url) do
    start_link(%{sitemap | "startUrl" => [url]})
  end
  def start_link(sitemap = %{"startUrl" => urls}) when is_list(urls) do
    opts =  [name: __MODULE__,
        urls: urls, 
        interval: 3600]

    GenSpider.start_link(__MODULE__, sitemap, opts)
  end

  def export(format \\ nil) do
    GenSpider.export(__MODULE__, format)
  end
  
  # Server (callbacks)

  def init(%{"selectors"=> rules}) do
   {:ok, rules}
  end

  def parse(response, rules) do
    result = rules
    |> Enum.map(fn(rule) -> 
      key = rule["id"]
      response.body
      |> select(rule["selector"])
      |> extract
      |> Enum.map(&({key, &1}))
    end)
    |> Enum.reduce([ [] ], fn(kvpairs, items) ->
      for kvpair <- kvpairs, item <- items, do: [kvpair | item]
    end)
    |> Enum.map(&Enum.into(&1, %{}))

    {:ok, result, rules}
  end
end
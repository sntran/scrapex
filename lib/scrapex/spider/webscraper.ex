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
  @type rule :: %{key => value}

  alias Scrapex.GenSpider
  alias GenSpider.Response
  import Scrapex.Selector
  use GenSpider

  require Logger

  # Client
  def start_link(sitemap = %{"startUrl" => url}) when is_binary(url) do
    start_link(%{sitemap | "startUrl" => [url]})
  end
  def start_link(sitemap = %{"startUrl" => urls}) when is_list(urls) do
    opts =  [
        urls: urls, 
        interval: 3600]

    GenSpider.start_link(__MODULE__, sitemap, opts)
  end

  def export(spider, format \\ nil) do
    GenSpider.export(spider, format)
  end
  
  # Server (callbacks)

  def init(%{"selectors"=> rules}) do
   {:ok, rules}
  end

  def parse(response, rules) do
    by_parent = group_by_parents(rules)

    results
    =  parse_level(response, "_root", by_parent)
    # @return: [ item ]
    |> Enum.map(&Enum.into(&1, %{}))

    {:ok, results, rules}
  end

  @spec parse_level(binary, binary, %{key => [rule]}) :: [item]
  defp parse_level(response, parent, rule_groups) do
    body = response.body
    rules = (rule_groups[parent] || [])

    rules
    |> Enum.map(fn
      (rule = %{"type" => "SelectorGroup"}) ->
        # For SelectorGroup, we collect all values into a list.
        # Note: This is different from WebScraper.IO extension.
        key = rule["id"]
        attribute = rule["extractAttribute"] || "text"
        values = select(body, rule["selector"]) |> extract(attribute)
        [[{key, values}]]
      (rule) ->
        key = rule["id"]
        multiple? = rule["multiple"]
        selectors = select(body, rule["selector"])
        selectors = if multiple?, do: selectors, else: Enum.take(selectors, 1)
        Logger.debug("Selecting #{rule["selector"]} into:")
        selectors
        |> Enum.map(fn(selector) ->
          [value] = extract(selector, "text")
          result = [[{key, value}]]

          Logger.debug("Parse response with #{rule["type"]}: #{rule["selector"]}")
          # For each key-value pair, return into a list, with
          # new key-value pair(s) if rule's selector is a link.
          case {rule["type"], rule_groups[key]} do
            {"SelectorText", _} ->
              regex = rule["regex"]
              case Regex.compile(rule["regex"]) do
                {:error, reason} -> result
                {:ok, ~r//} -> result
                {:ok, regex} ->
                  [value|_] = Regex.run(regex, value)
                  [[{key, value}]]
              end
            {"SelectorLink", nil} ->
              # Link with no child rule just returns the text value
              result
            {"SelectorLink", _} ->
              [href] = extract(selector, "href")
              url = GenSpider.Response.url_join(response, href)
              result = [[{key, value}, {key <> "-href", url}]]

              request = GenSpider.request(url, fn({:ok, response}) ->
                # Get sub nodes as a tuple list.
                parse_level(response, rule["id"], rule_groups)
              end)
              subvalues = GenSpider.await(request)
              # @return [ item ]
              combine(result, subvalues)
            {"SelectorElement", nil} ->
              # Don't return SelectorElement in result
              []
            {"SelectorElement", _} ->
              # Only use the results scraped from children rules.
              parse_level(%{body: selector}, key, rule_groups)
            {"SelectorElementAttribute", _} ->
              [value] = extract(selector, rule["extractAttribute"])
              [[{key, value}]]
            _ ->
              result
          end
        end)
      # @return [ item ]
      |> Enum.concat
    end)
    |> Enum.reduce(&combine/2)
  end

  @spec combine([item], [item]) :: [item]
  defp combine([], right), do: right
  defp combine(left, []), do: left
  defp combine(left, right) do
    for litem <- left, ritem <- right, do: Enum.concat(litem, ritem)
  end

  @spec group_by_parents([rule], binary) :: %{key => [rule]}
  defp group_by_parents(selectors, key \\ "parentSelectors") do
    Enum.reduce(selectors, %{}, fn(selector, groups) ->
      Enum.reduce(selector[key], groups, fn(parent, groups) ->
        Dict.update(groups, parent, [selector], &[selector|&1])
      end)
    end)
  end
end
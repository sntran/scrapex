GenSpider
=========

The flow of GenSpider

- GenSpider.start_link
  - GenSpider.init
    - Mod.init

  - GenSpider.handle_info(:timeout): message from start_link
  - GenSpider.handle_info(:crawl): start the full crawl
    - Mod.start_requests
      - Mod.make_requests_from_url
        - GenSpider.request(url, &parse/1): called inside GenSpider
          - Request.async
            - Create a task with Request.do_request
              - do_request calls `parse(response)`
              # Up to here, everything is asynchronous, result will be handled in handle_info({ref,...})
  # Receive data after request and parsed.
  - GenSpider.handle_info({ref, {:ok, data}})
    - remove request with ref from spider.requests
    - store data into spider.data
    - if last request and interval option,
      - send(self, :crawl, interval)
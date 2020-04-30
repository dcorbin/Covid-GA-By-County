require 'selenium-webdriver'
require 'fileutils'
require 'pathname'
require 'nokogiri'
require 'http-client'

# URL = 'https://dph.georgia.gov/covid-19-daily-status-report'

class ResourceFetcher
  def fetch(url, &block)
    response = HTTP::Client.get(url)
    if response.code == 200
      block.call(response)
    else
      $stderr.puts("Fetch failed: " + response.inspect)
      raise "Aborting..."
    end
  end
end

class CountyDataFetcher
  URL = 'https://ga-covid19.ondemand.sas.com'

  def initialize
    @resource_fetcher = ResourceFetcher.new
  end
  def fetch
    main_source_url = @resource_fetcher.fetch(URL) do |response|
      html_doc = Nokogiri::HTML(response.body)
      URL + html_doc.css("script").last['src']
    end

    json_data = @resource_fetcher.fetch(main_source_url) do |response|
      response.body.split(/\n/).find{ |line|line =~ /function/}.
          sub(/.*COUNTYCASES":/, '').sub(/\].*/, ']')
    end

    JSON.parse(json_data)
  end
end

session_timestamp = Time.now.localtime

filename = Pathname(ENV['DATA_DIR'] || "./data") + session_timestamp.strftime("%Y%m%d.json")
data = CountyDataFetcher.new.fetch
File.open(filename, "w") {|file| file.puts JSON.pretty_generate(data)}
$stderr.puts "%d records" % [ data.size ]

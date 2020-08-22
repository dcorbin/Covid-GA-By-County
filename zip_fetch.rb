require 'selenium-webdriver'
require 'fileutils'
require 'pathname'
require 'nokogiri'
require 'http-client'
require 'zip'
require 'csv'

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

KNOWN_PROPERTIES = {
    county_resident: proc {|v| v},
    positive: proc {|v| v.to_i},
    deaths: proc {|v| v.to_i},
    hospitalization: proc {|v| v.to_i},
    case_rate: proc {|v| v.to_f},
}
ZIP_URL = 'https://ga-covid19.ondemand.sas.com/docs/ga_covid_data.zip'
class CountyDataFetcher
  def initialize
    @resource_fetcher = ResourceFetcher.new
  end
  def fetch
    data_rows = []
    Dir.mktmpdir("covid-ga-download") do |temp_dir|
      temp_dir = Pathname(temp_dir)
      $stderr.puts "TempDir: #{temp_dir}"
      zip_file_name = Pathname(temp_dir) + "GA-County.zip"
      File.open(zip_file_name, "w") do |file|
        @resource_fetcher.fetch(ZIP_URL) do |response|
          file.write(response.body)
        end
      end
      Zip::File.open(zip_file_name) do |zip_file|
        zip_file.each do |entry|
          if entry.name == 'countycases.csv'
            case_file_name = temp_dir + "countycases.csv"
            entry.extract(case_file_name)
            headers = nil
            CSV.foreach(case_file_name) do |row|
              if headers
                record = {}
                row.each_with_index { |datum, index|
                  property = headers[index]
                  parser = KNOWN_PROPERTIES[property.to_sym]
                  if parser.nil?
                    raise("Unknown Property '#{property}'")
                  end
                  record[headers[index]] = parser.call(datum)
                }
                data_rows << record
              else
                headers = row.collect { |h| h.downcase }
              end
            end
          end
        end
      end
    end
    data_rows
  end
end

session_timestamp = Time.now.localtime

filename = Pathname(ENV['DATA_DIR'] || "./data") + session_timestamp.strftime("by-date/%Y-%m-%d.json")
data = CountyDataFetcher.new.fetch
File.open(filename, "w") {|file| file.puts JSON.pretty_generate(data)}
$stderr.puts "%d records" % [ data.size ]
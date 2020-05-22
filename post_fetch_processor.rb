require 'values'
require 'json'
require 'date'
require 'pathname'
require 'daily_county_record'

FetchedRecord = Value.new(:county, :positive, :death, :hospitalized, :positives_per_100k)
class FetchedRecord
  def self.load_file(filename)
    File.open(filename, "r") do |file|
      JSON.parse(file.read).collect do |record|
        FetchedRecord.new(
            record['county_resident'],
            record['Positive'].to_i,
            record['DEATHS'].to_i,
            record['HOSPITALIZATION'].to_i,
            record['case_rate'].to_f)
      end
    end
  end
end


class DailyCountyRecord
  def self.from_fetched_records(fetched_record, date)
    DailyCountyRecord.new(
        fetched_record.county,
        date,
        fetched_record.positive,
        fetched_record.death,
        fetched_record.hospitalized,
        fetched_record.positives_per_100k)
  end
end

class Datastore
  def initialize(root)
    @root = root
  end

  def load_all
    dir = @root + "by-date/*.json"
    results = {}
    Dir.glob(dir) do |filename|
      match = %r<.*/(\d\d\d\d)-(\d\d)-(\d\d).json>.match(filename.to_s)
      raise "Unable to parse date from #{filename}" if match.nil?
      date = Date.civil(match[1].to_i, match[2].to_i, match[3].to_i)
      results[date] = FetchedRecord.load_file(filename)
    end
    results
  end
end

def build_table(fetched_data_by_date)
  fetched_data_by_date.keys.sort[1..-1].collect do |date|
    fetched_records = fetched_data_by_date[date]
    fetched_records.collect {|record|
      DailyCountyRecord.from_fetched_records(record, date)
    }
  end.flatten
end

data_dir = Pathname(ENV['DATA_DIR'] || "./data")

fetched_data_by_date = Datastore.new(data_dir).load_all
File.open(data_dir + "table.json", 'w') do |file|
  file.puts JSON.pretty_generate(build_table(fetched_data_by_date))
end

require 'values'
require 'json'
require 'date'

FetchedRecord = Value.new(:county, :positives, :deaths, :hospitalizations, :positives_per_100k)
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

DailyRecord = Value.new(:positives, :deaths, :hospitalizations, :positives_per_100k,
                        :new_positives, :new_deaths, :new_hospitalizations)

class DailyRecord
  def self.from_fetched_records(fetched_record, prior_fetched_record)
    DailyRecord.new(
        fetched_record.positives,
        fetched_record.deaths,
        fetched_record.hospitalizations,
        fetched_record.positives_per_100k,
        fetched_record.positives - prior_fetched_record.positives,
        fetched_record.deaths - prior_fetched_record.deaths,
        fetched_record.hospitalizations - prior_fetched_record.hospitalizations)
  end
  def to_json(*args)
    to_h.to_json(*args)
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

def index_data_by_county_then_date(fetched_data_by_date)
  counties = fetched_data_by_date.values.first.collect { |x| x.county }
  dated_data_by_county = {}
  counties.each {|county| dated_data_by_county[county] = {}}
  fetched_data_by_date.each_pair do |date, fetched_records|
    prior_date = date - 1
    fetched_records.each {|record|
      prior_record = if fetched_data_by_date.has_key?(prior_date)
                       prior_data = fetched_data_by_date[prior_date]
                       prior_data.find {|r| r.county == record.county}
                     else
                       FetchedRecord.new(record.county, 0, 0, 0, 0.0)
                     end
      dated_data_by_county[record.county][date] = DailyRecord.from_fetched_records(record, prior_record)
    }
  end
  dated_data_by_county
end

data_dir = Pathname(ENV['DATA_DIR'] || "./data")

fetched_data_by_date = Datastore.new(data_dir).load_all
dated_data_by_county = index_data_by_county_then_date(fetched_data_by_date)
File.open(data_dir + "summary.json", 'w') do |file|
  file.puts JSON.pretty_generate(dated_data_by_county)
end

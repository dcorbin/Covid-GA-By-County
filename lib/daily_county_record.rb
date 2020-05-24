require 'values'

DailyCountyRecord = Value.new(:county, :date, :positive, :death, :hospitalized, :positives_per_100k,
                              )

class DailyCountyRecord
  def self.from_hash(h)
    date_parser = %r<(\d{4})-(\d\d)-(\d\d)>.match(h['date'])

    DailyCountyRecord.new(
        h['county'],
        Date.new(date_parser[1].to_i, date_parser[2].to_i, date_parser[3].to_i),
        h['positives'],
        h['deaths'],
        h['hospitalizations'],
        h['positives_per_100k'],
        h['new_positives'],
        h['new_deaths'],
        h['new_hospitalizations']
    )
  end

  def to_json(*args)
    to_h.to_json(*args)
  end
end
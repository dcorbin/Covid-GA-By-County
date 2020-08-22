require 'json'
# { x3
#     "measure": "state_total",
#     "county": "Georgia",
#     "report_date": "2020-02-01",
#     "positives": 0,
#     "deathcnt": 0,
#     "positives_cum": 0,
#     "death_cum": 0,
#     "moving_avg_cases": 0,
#     "moving_avg_deaths": 0
# },
# PRDO
#   {
#     "county_resident": "Appling",
#     "positive": null,
#     "deaths": null,
#     "hospitalization": null,
#     "case_rate": null
#   },
#
def safe(n)
  return n.to_s if n
  "nil"
end

def normalizeLive(r)
  if r['Positive']
    r['positive'] = r['Positive']
  end
  if r['DEATHS']
    r['deaths'] = r['DEATHS']
  end
  r
end
def compareRecords(x3, live)
  result = x3['report_date'] + ": "
  p =  x3['positives_cum'] == live['positive']
  d =  x3['death_cum']  == live['deaths']

  if p and d then
    return result +  "Ok"
  end
  problems = []
  unless p then
    problems << "Positives %d vs %s" % [x3['positives_cum'], safe(live['positive'])]
  end
  unless d then
    problems << "Deaths %d vs %s" % [x3['death_cum'], safe(live['deaths'])]
  end
  result + problems.join(', ')
end

def readJson(filename)
  File.open(filename) do |file|
    JSON.parse(file.read)
  end
end
def findRecord(county, dateString)
  filename = "data/by-date/#{dateString}.json"
  return nil unless File.exist?(filename)
  records = readJson(filename)
  records.find {|r| r['county_resident'] == county}
end
x3records = readJson("hack/x3.json")
# dates = x3records.collect{|r| r['report_date']}.sort.uniq
fultonX3 = x3records.select{|r| r['county'] == 'Fulton'}

fultonX3.each do |x3|
  liveRecord = findRecord("Fulton", x3['report_date'])
  if liveRecord
    comparisonResult = compareRecords(x3, normalizeLive(liveRecord))
    puts comparisonResult
  end
end
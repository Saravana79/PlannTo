desc 'update aggregated detail'
task :aggregated_detail_process => :environment do
  log = Logger.new 'log/aggregated_detail_process.log'
  [*"4-10-2013".to_date .. Date.today].each do |date|
    p date
    log.debug date
    AggregatedDetail.update_aggregated_detail(date, 'publisher')
    AggregatedDetail.update_aggregated_detail(date, 'advertisement')
    AggregatedDetail.update_aggregated_detail(date, 'sid')
  end
end
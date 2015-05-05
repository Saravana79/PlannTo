desc 'update aggregated detail'
task :aggregated_detail_process_all => :environment do
  log = Logger.new 'log/aggregated_detail_process.log'
  [*"4-10-2013".to_date .. Date.today].each do |date|
    p date
    log.debug date
    AggregatedDetail.update_aggregated_detail(date, 'publisher')
    AggregatedDetail.update_aggregated_detail(date, 'advertisement')
    AggregatedDetail.update_aggregated_detail(date, 'sid')
  end
end

desc 'update aggregated detail force => date => "date/month/year"'
task :aggregated_detail_process_force, [:date] => :environment do |_, args|
  args.with_defaults(:date => Time.now)
  time = args[:date].to_time rescue Time.now
  AggregatedDetail.update_aggregated_details_from_mongo_reports(time, 'advertisement', "Advertisement", true)
end

desc 'Cookie Match update mapping to redis_rtb'
task :cookie_match_update_mapping => :environment do
  query = "SELECT * FROM `cookie_matches` WHERE `cookie_matches`.`google_mapped` = 0"
  page = 1
  begin
    cookie_matches = CookieMatch.paginate_by_sql(query, :page => page, :per_page => 6000)
    p "page => #{page}"
    $redis_rtb.pipelined do
      cookie_matches.each do |cookie_match|
        $redis_rtb.set("cm:#{cookie_match.google_user_id}", cookie_match.plannto_user_id)
        $redis_rtb.expire("cm:#{cookie_match.google_user_id}", 2.weeks)
      end
    end
    page += 1
  end while !cookie_matches.empty?
end
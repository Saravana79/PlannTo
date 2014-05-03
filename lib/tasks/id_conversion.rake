namespace :id_conversion do
  desc 'Convert add_impression id to old_id'
  task :to_old_id, [:batch_size] => :environment do |t, args|
    args.with_defaults(:batch_size => 500)
    batch_size = args[:batch_size].to_i
    # Item update
    log = Logger.new 'log/id_conversion.log'

    count = 0
    AddImpression.find_in_batches(:batch_size => batch_size) do |each_impressions|
      each_impressions.each_with_index do |each_impression, ind|
        check_val = count + ind + 1
        p "Now ------------- #{check_val}-------------"
        log.debug "Now ------------- #{check_val}-------------"
        each_impression.update_attributes!(:old_id => each_impression.id)
      end
      count = count + 500
    end
  end

end
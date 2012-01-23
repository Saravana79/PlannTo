class ReviewsController < ApplicationController
  respond_to :html, :js

  def index
    @reviews = case params[:sort]
    when 'voting'
      Review.sort_by_vote_count
    when 'time_asc'
      Review.order 'created_at'
    when 'time_desc'
      Review.order 'created_at desc'
    when 'rating_asc'
      Review.order 'rating, created_at desc'
    when 'rating_desc'
      Review.order 'rating desc, created_at desc'
    else
      logger.error('Inside Else');
      Review.order 'created_at desc'
    end

    respond_to do |format|
      format.html
      format.js
    end
  
  end

  def create
    @review = Review.new(params[:review])
    @review.rate_it(params[:rating],1) unless params[:rating].nil? 
    #    @pros = Pro.new(params[:pro])
    #    logger.error('Review Details :: ')
    #    logger.error(@pros.inspect)
    @review.save
    logger.error('Review description ::' + params.inspect)
    respond_with @review, :location => reviews_url
  end

  def show
    logger.error 'Params => ' + params[:id]
    @review = Review.find params[:id]
  end

  def destroy
    @review = Review.find(params[:id])
    @review.destroy
    respond_with @review, :location => reviews_url
  end
  
  def new
    @review = Review.new
    @review.pros.build
    @review.cons.build
    @review.best_uses.build
    @item = Car.find 307
  end

  def sort
    @reviews = case params[:sort]
    when :voting
      Review.sort_by_vote_count
    when :time_asc
      Review.order 'created_at'
    when :time_desc
      Review.order 'created_at desc'
    when :rating_asc
      Review.order 'rating, created_at desc'
    when :rating_desc
      Review.order 'raitng desc, created_at desc'
    else
      Review.order 'created_at desc'
    end

    respond_to do |format|
      format.html
      format.js
    end
  end
  
  private
  
  def pros_factory(pros,review)
    new_pros = []
    pros.each do |i|
      pro = Pro.where("title = ?", i)
      if pro.empty?
        new_pro = Pro.new
        new_pro.title = i
        new_pro.item = review.item
        new_pro.user = review.user
        new_pro.save
        new_pros.push new_pro
      else
        new_pros.push pro
      end
    end
    review.pros.push new_pros
  end
  
  def cons_factory(cons,review)
	new_cons = []
	cons.each do |i|
		con = Con.where("title = ?", i)
		if con.empty?
			new_con = Con.new
			new_con.title = i
			new_con.item = review.item
			new_con.user = review.user
			new_con.save
			new_cons.push new_con
		else
			new_cons.push con
		end
	end
	review.cons.push new_cons
end

def best_uses_factory(best_uses,review)
	new_best_uses = []
	best_uses.each do |i|
		best_use = Best_Use.where("title = ?", i)
		if best_use.empty?
			new_best_use = Best_Use.new
			new_best_use.title = i
			new_best_use.item = review.item
			new_best_use.user = review.user
			new_best_use.save
			new_best_uses.push new_best_use
		else
			new_best_uses.push best_use
		end
	end
	review.best_uses.push new_best_uses
end

 def csv_to_array(csv)
   csv.strip.split(",").map{|i| i.strip}
 end
end

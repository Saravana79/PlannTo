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
    @review = Review.create(params[:review])
    @review.rate_it(params[:rating],1) unless params[:rating].nil? 
#    @pros = Pro.new(params[:pro])
#    logger.error('Review Details :: ')
#    logger.error(@pros.inspect)
    #@review.save
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

end

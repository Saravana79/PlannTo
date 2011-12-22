class ReviewsController < ApplicationController
respond_to :html, :js

  def index
    @reviews = Review.all
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

end

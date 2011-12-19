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
  
  # def show
    # review = Review.find 3
    # user = User.find 1
    # user.voted_on? review
    # user.vote_count
  # end

end

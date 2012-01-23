class VotesController < ApplicationController

  def create
    voter  = User.find(1)
    voteable = params[:parent].camelize.constantize.find(params[:parent_id])
    if voter.voted_on?voteable
      if voter.voted_which_way?(voteable, params[:vote].to_sym)
        voter.clear_votes(voteable)
      else
        logger.error "Vote #{ params[:vote]}"
        voter.vote voteable,{:direction => params[:vote], :exclusive => true ,:id => params[:id]}
      end
    else
      voter.vote voteable,:direction => params[:vote] 
    end
    @vote = voter.fetch_vote(voteable)
    respond_to do |format|
      format.js 
    end
  end

    def index
    respond_to do |format|
      format.js{render :nothing => true}
    end
  end

end

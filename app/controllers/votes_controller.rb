class VotesController < ApplicationController
   before_filter :authenticate_user!
  require "resque"
  skip_before_filter :verify_authenticity_token

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

  def add_vote
    if user_signed_in?
      voter = current_user
      @voteable = voteable = params[:parent].camelize.constantize.find(params[:id])
      if voter.voted_on?voteable
        if voter.voted_which_way?(voteable, params[:vote].to_sym)
          voter.clear_votes(voteable)
        else
          logger.error "Vote #{ params[:vote]}"
          voter.vote voteable,{:direction => params[:vote], :exclusive => true ,:id => current_user.fetch_vote(voteable).try(:id)}
        end
      else
        voter.vote voteable,:direction => params[:vote]
      end
      
      Vote.get_vote_list(current_user)
      Resque.enqueue(VotingPoint, current_user.id, @voteable.id, params[:parent])
      #Point.add_voting_point(current_user, @voteable)
      
      if  !@voteable.is_a?BuyingPlan and !@voteable.is_a?UserAnswer
        UserActivity.save_user_activity(current_user,params[:id],params[:vote] == 'down'? 'downvoted' : 'voted',@voteable.type == "AnswerContent" ? "Answer" : @voteable.sub_type,"",request.remote_ip)
      end
      
      if @voteable.is_a?BuyingPlan
        UserActivity.save_user_activity(current_user,params[:id],params[:vote] == 'down'? 'downvoted' : 'voted','Buying Plan',"",request.remote_ip)
      end 
        
      @vote = voter.fetch_vote(voteable)
      @voteable = params[:parent].camelize.constantize.find(params[:id])
    else
      render :nothing => true
    end
  end

  def index
    respond_to do |format|
      format.js{render :nothing => true}
    end
  end

end

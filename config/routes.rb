PlanNto::Application.routes.draw do
 
namespace :admin do
  resources :users
  resources :impression_reports
  resources :click_reports
  resources :order_histories
  resources :advertisements
  resources :buying_plans do
  collection do  
    get :search
    post :search
    get :proposal
    post :proposal_save
    get :proposal_list
   end
   member do
     get  :view_proposal
     get  :proposal_edit
   end
   end
  resources :feeds do
    member do
      get :add_vote
      get :approve
      get :reject
      post :content_action
    end
   end  
  resources :follows
 end
  match "sitemap.xml", :to => "sitemap#index", :defaults => {:format => :xml}
  get "home/index"
  resources :follows do
   collection do 
     get :user_follow
   end
  end   
  resources :error_messages
  match "/terms_conditions" ,:to => "home#terms_conditions"
  match "/privacy_policy" ,:to => "home#privacy_policy"
  get "/contact_us" => "contact_us#new"
  match "/about_us",:to => "home#about_us"
  match "/opt_out",:to => "home#opt_out"
  match "/opt_out_submit",:to => "home#opt_out_submit"
  match "/targeting",:to => "home#targeting"
  match "/current_user_info",:to => "home#current_user_info"
  match "/external_page",:to => "products#external_page"
  match "/search_planto",:to => "products#search_items"
  
  match "/get_class_names",:to => "contents#get_class_names"
  match "/external_page",:to => "products#external_page"
  match "/where_to_buy_items",:to => "products#where_to_buy_items"
  match "/product_offers",:to => "products#product_offers"
  match "/product_autocomplete",:to => "products#product_autocomplete"
  match "/get_item_for_widget",:to => "products#get_item_for_widget"
  match "/show_search_widget",:to => "products#show_search_widget"
  match "/get_item_item_advertisment",:to => "products#get_item_item_advertisment"
  
  match "/advertisement",:to => "products#advertisement"
  match "/current_user_info",:to => "home#current_user_info"
  match "/get_class_names",:to => "contents#get_class_names"
  match "products/ratings",:to => "products#ratings"
  
  resources :contact_us
  resources :newuser_wizards do
  collection do
    get :product_select
    get :previous
  end
   member do
    get :product_delete
   end 
  end 
  
  match "/newuser_wizard", :to => "newuser_wizards#new"
  devise_for :users, :controllers => { :sessions => "users/sessions", :registrations => "users/registrations", :omniauth_callbacks => "users/omniauth_callbacks" ,:passwords => "users/passwords" } 
  resource :oauth,:controller=>"oauth" 

 match "oauth_callback" => "oauth#create"
 match "content_post" => "oauth#content_post"
  devise_scope :user do
    #get 'users/sign_up/:invitation_token' => 'users/registrations#invited', :as => :invite
    get '/users/sign_out' => 'devise/sessions#destroy'
  end
  
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :contfroller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  #  match 'products/:id' => 'products#show', :as => :products
  # This route can be invoked with purchase_url(:id => product.id)
  resources :history_details  
  resources :votes do
    collection do
      post "add_vote"
    end
  end
  match 'external_contents/:content_id' => 'external_contents#show', :as => 'external_content'
  
  match 'admin/search', :to => 'admin#index'
  match ':search_type/search' => 'search#index'
  resources :search do
    collection do
      get :autocomplete_items
      get :preference_items
      get :search_items
      get :search_items_by_relavance
    end
  end
  match ':search_type/related-items/:car_id' => 'related_items#index'
  match 'groups/:id' => 'car_groups#show', :as => 'car_groups'
  match ':type/topics' => 'products#topics'
  match 'my_feeds'  => 'contents#my_feeds'
  # Sample resource route (maps HTTP verbs to controller actions automatically):

  
resources :field_values, :only => [:create]
resources :answer_contents  

# match 'accounts/:username', :to => "accounts#index", :as => "accounts"


resources :accounts do
    put :update
    member do
      put :change_password
      get :followers
      get :add_review
      get :add_information
      get :add_photo
    end
    collection do
      get :profile
     end 
  end
  match 'account_update', :to => "accounts#update", :as => "account_update"
  match 'personal_deals', :to => "preferences#personal_deals"
 
  resources :preferences do
    collection do
      get :give_advice
      get :owned_item
      get :considered_item_delete
      post :owned_description_save
      get :get_advice
      post :add_preference
      get :create_preference
      post :create_preference
      get  :deals_filter
      get :edit_preference
      post :save_advice
      get :update_preference
      get :plan_to_buy
      get :delete_buying_plan
      delete :delete_buying_plan
      get :update_question
      get :edit_user_question
      delete :delete_answer
      get :edit_answer
      post :update_answer
    end
    
  end
   match 'create_buying_plan' => 'preferences#new'
   match 'preferences/:search_type/:uuid' => 'preferences#show'
   match ':itemtype/guides/:guide_type' => 'contents#search_guide'
   match ':itemtype/:item_id/guides/:guide_type' => 'contents#search_guide'
   
  resources :cars do
        resources :reports
        resources :shares
  end
   
  #match "/contents/update_guide" => 'contents#update_guide'

  resources :contents do
   resources :reports 
  collection do
    get :filter
    get :edit_guide_ajax
    post :update_guide
    get :feed
    get :feeds
    post :search_contents
    get :search_autocomplete_list
    get :search_related_contents
    get :quick_new
  end
  match "/contents/search" => 'contents#search'
 
  post :search
  resources :comments 
    collection do
      get :feed
    end
  end
resources :comments do
    resources :reports 
   end 
  resources :event_contents
  resources :plannto_contents
  resources :article_contents do
    put :download
    collection do
      post :download
      post :new_popup
      get :bmarklet
      #post :update - by shanmukha I have confused why they defined update as collection with  post method .  Actualy in restful method update is put method
      put :download
    end
  end
  resources :mobiles do
        resources :shares
  end 
  resources :tablets do
        resources :shares
  end 
  resources :cameras do
        resources :shares
  end  
  resources :games do
        resources :shares
  end  
  resources :bikes do
        resources :shares
  end   
  resources :cycles do
        resources :shares
  end   
  resources :mobiles do 
    resources :reports
  end  
  resources :tablets do 
    resources :reports
   end 
  resources :vendors do 
    resources :reports
   end 
  resources :cameras do 
    resources :reports
  end  
  resources :bikes do
    resources :reports
  end  
  resources :cycles do
    resources :reports
  end  
  resources :bike_groups
  resources :manufacturers
  resources :car_groups  
  resources :attribute_tags
  resources :topics
  resource :facebook, :except => :create do
    get :callback, :to => :create
    get :friends
    get :wall_post
    get :show_friends
    post :wall_content
  end
  resources :products do
    collection do
      get 'related_items'
      get 'follow_buttons'
    end
    member do
      get 'related_products'
      get 'specification'
      get 'review_it'
      get 'add_item_info'
    end
  end
  resources :items do
       resources :reports    
    collection do
      get :compare
    end
    member do
      get 'follow_item_type'
      get 'plan_to_buy_item'
      get 'own_a_item'
      get 'follow_this_item'
    end
  end
  resources :reviews
  resources :review_contents
  resources :question_contents
  resources :pros
  resources :questions
  resources :answers
  resources :tips
  resources :invitations
  match 'invitation/accept/:token' => "invitations#accept", :as => :accept_invitation
    
  resources :imageuploads, :only => [:show] 
  match "/imageuploads_tag" => 'imageuploads#tag' 
  match "/autocomplete_tag" => 'imageuploads#autocomplete_tag' 
   match "/messages/search_users" => 'messages#search_users'
   
  resources :messages
  match "/create_message/:id/:method" => 'messages#create_message', :as => :create_message
  match "/messages/block_user/:id" => 'messages#block_user', :as => :block_user
  match "/messages/:id/threaded" => 'messages#threaded_msg', :as => :threaded_msg
 
  
 # match '/:search_type', :to => "products#index"
  
  
  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
 
  root :to => 'home#index'
  #root :controller => :item, :action => :index
  # See how all your routes lay out with "rake routes"


  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  match ':controller(/:action(/:id(.:format)))'

  mount Resque::Server, :at => "/resque"  

  match '/:username', :to => "accounts#profile", :as => "profile"
  
  
end

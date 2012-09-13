PlanNto::Application.routes.draw do
  match "sitemap.xml", :to => "sitemap#index", :defaults => {:format => :xml}
  get "home/index"
  resources :follows
  resources :error_messages
  match "/terms_conditions" ,:to => "home#terms_conditions"
  match "/privacy_policy" ,:to => "home#privacy_policy"
  get "/contact_us" => "contact_us#new"
  match "/about_us",:to => "home#about_us"
  resources :contact_us
  resources :newuser_wizards
  match "/newuser_wizard", :to => "newuser_wizards#new"
  devise_for :users, :controllers => { :sessions => "users/sessions", :registrations => "users/registrations", :omniauth_callbacks => "users/omniauth_callbacks" } 
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
    end
    collection do
      get :profile
     end 
  end
  match 'account_update', :to => "accounts#update", :as => "account_update"

 
  resources :preferences do
    collection do
      get :give_advice
      get :get_advice
      post :add_preference
      post :create_preference
      get :edit_preference
      post :save_advice
      get :update_preference
      get :plan_to_buy
      get :delete_buying_plan
      get :update_question
    end
  end
   match 'preferences/:search_type/:uuid' => 'preferences#show'
   match ':itemtype/guides/:guide_type' => 'contents#search_guide'
   match ':itemtype/:item_id/guides/:guide_type' => 'contents#search_guide'
   
  resources :cars do
        resources :shares
  end
   
  #match "/contents/update_guide" => 'contents#update_guide'

  resources :contents do
   resources :reports 
  collection do
    get :filter
    post :update_guide
    get :feed
    get :feeds
    post :search_contents
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
  resources :bikes do
        resources :shares
  end   
  resources :cycles do
        resources :shares
  end   
  resources :mobiles
  resources :tablets
  resources :cameras
  resources :bikes
  resources :cycles
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
    end
    member do
      get 'related_products'
      get 'specification'
      get 'review_it'
      get 'add_item_info'
    end
  end
  resources :items do
        
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
  resources :messages
  resources :tips
  resources :invitations
  match 'invitation/accept/:token' => "invitations#accept", :as => :accept_invitation
    
  resources :pages, :only => [:show] 
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

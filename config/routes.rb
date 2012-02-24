PlanNto::Application.routes.draw do

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  #  match 'products/:id' => 'products#show', :as => :products
  # This route can be invoked with purchase_url(:id => product.id)
  match 'admin/search', :to => 'admin#index'
  match ':search_type/search' => 'search#index'
  match ':search_type/related-items/:car_id' => 'related_items#index'
  # Sample resource route (maps HTTP verbs to controller actions automatically):

  match 'profile', :to => "accounts#profile", :as => "profile"
  resources :accounts, :only => [:index] do
    put :update
  end
  match 'account_update', :to => "accounts#update", :as => "account_update"
  match 'preferences/:search_type/:uuid' => 'preferences#show'
  resources :preferences do
    collection do
      get :give_advice
      get :get_advice
      post :add_preference
      get :edit_preference
      post :save_advice
      get :update_preference
    end
  end
  resources :cars do
        resources :shares
  end  
  resources :contents do
      resources :comments
    collection do
      get :feed
    end
  end
  resources :article_contents do
    collection do
      post :download
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
  resources :mobiles
  resources :tablets
  resources :cameras
  resources :manufacturers
  resources :car_groups
  resource :facebook, :except => :create do
    get :callback, :to => :create
    get :friends
    get :wall_post
    get :show_friends
    post :wall_content
  end
  resources :products do
   
    member do
      get 'related_products'
      get 'specification'
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
  resources :pros
  resources :votes
  resources :questions
  resources :answers
  resources :messages
  resources :tips
  resources :invitations, :only => [:create]
  resources :pages, :only => [:show] 
  match "/create_message/:id/:method" => 'messages#create_message', :as => :create_message
  match "/messages/block_user/:id" => 'messages#block_user', :as => :block_user
  match "/messages/:id/threaded" => 'messages#threaded_msg', :as => :threaded_msg
  devise_for :users, :controllers => { :sessions => "users/sessions", :registrations => "users/registrations" } 
  devise_scope :user do
  get 'users/sign_up/:invitation_token' => 'users/registrations#invited', :as => :invite
  end
  
  
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
  root :to => 'items#index'
  #root :controller => :item, :action => :index
  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  match ':controller(/:action(/:id(.:format)))'
end

PlanNto::Application.routes.draw do
 
namespace :admin do
  resources :payment_reports
  resources :users
  # resources :impression_reports
  resources :click_reports
  resources :order_histories do
    collection do
      post "import"
    end
  end
  resources :advertisements do
    collection do
      get "change_ad_status"
      get "review"
      get "approved"
      get "denied"
    end
  end
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
  resources :source_categories, :only => [:index, :update]
 end
  get "sitemap.xml", :to => "sitemap#index", :defaults => {:format => :xml}
  get "home/index"
  resources :follows do
   collection do 
     get :user_follow
   end
  end   
  resources :error_messages

  get "/admin/impression_reports", :to => "admin/order_histories#index"
  get "/admin/orders", :to => "admin/order_histories#orders", :as => :admin_orders
  get "/admin/get_item_details", :to => "admin/order_histories#get_item_details"

  get "/admin/orders/edit/:id", :to => "admin/order_histories#edit", :as => :admin_order_edit
  put "/admin/orders/update", :to => "admin/order_histories#update", :as => :admin_order_update
  delete "/admin/orders/delete", :to => "admin/order_histories#destroy", :as => :admin_order_destroy
  get "/admin/get_item_details", :to => "admin/order_histories#get_item_details"


  get "/terms_conditions" ,:to => "home#terms_conditions"
  get "/privacy_policy" ,:to => "home#privacy_policy"
  get "/contact_us" => "contact_us#new"
  get "/about_us",:to => "home#about_us"
  post "/opt_out",:to => "home#opt_out"
  post "/opt_out_submit",:to => "home#opt_out_submit"
  get "/targeting",:to => "home#targeting"
  get "/current_user_info",:to => "home#current_user_info"
  get "/external_page",:to => "products#external_page"
  get "/search_planto",:to => "products#search_items"
  
  get "/get_class_names",:to => "contents#get_class_names"
  get "/external_page",:to => "products#external_page"
  get "/where_to_buy_items",:to => "products#where_to_buy_items"
  get "/where_to_buy_items_vendor",:to => "products#where_to_buy_items_vendor"
  get "/widget_for_women",:to => "products#widget_for_women"
  get "/elec_widget_1",:to => "products#elec_widget_1"
  get "/price_vendor_details",:to => "products#price_vendor_details"
  get "/get_price_from_vendor",:to => "products#get_price_from_vendor"
  get "/price_text_vendor_details",:to => "products#price_text_vendor_details"
  get "/book_price_widget",:to => "products#book_price_widget"
  get "/sports_widget",:to => "products#sports_widget"
  get "/vendor_widget",:to => "products#vendor_widget"
  get "/product_offers",:to => "products#product_offers"
  get "/product_autocomplete",:to => "products#product_autocomplete"
  get "/get_item_for_widget",:to => "products#get_item_for_widget"
  get "/show_search_widget",:to => "products#show_search_widget"
  get "/get_item_item_advertisment",:to => "products#get_item_item_advertisment"
  
  get "/advertisement",:to => "products#advertisement"
  # get "/current_user_info",:to => "home#current_user_info"
  get "/get_class_names",:to => "contents#get_class_names"
  get "products/ratings",:to => "products#ratings"
  
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
  
  get "/newuser_wizard", :to => "newuser_wizards#new"
  # devise_for :users, :controllers => { :sessions => "users/sessions", :registrations => "users/registrations", :omniauth_callbacks => "users/omniauth_callbacks" ,:passwords => "users/passwords" }
  devise_for :users, :controllers => { sessions: 'users/sessions', passwords: 'users/passwords', registrations: 'users/registrations', omniauth_callbacks: 'users/omniauth_callbacks' }
  resource :oauth,:controller=>"oauth" 

 post "oauth_callback" => "oauth#create"
 post "content_post" => "oauth#content_post"
  devise_scope :user do
    #get 'users/sign_up/:invitation_token' => 'users/registrations#invited', :as => :invite
    get '/users/sign_out' => 'devise/sessions#destroy'
    get "/users/publisher_sign_up" => "users/registrations#publisher_sign_up"
    post "/users/publisher_create" => "users/registrations#publisher_create"
  end
  
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   get 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :contfroller and :action

  # Sample of named route:
  #   get 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  #  get 'products/:id' => 'products#show', :as => :products
  # This route can be invoked with purchase_url(:id => product.id)
  resources :history_details

  get "plannto/housing_ad_click" => "history_details#housing_ad_click"
  resources :votes do
    collection do
      post "add_vote"
    end
  end
  get 'external_contents/:content_id' => 'external_contents#show', :as => 'external_content'
  
  get 'admin/search', :to => 'admin#index'
  get ':search_type/search' => 'search#index'
  resources :search do
    collection do
      get :autocomplete_items
      get :preference_items
      get :search_items
      get :autocomplete_source_items
      get :search_items_by_relavance
      get :search_items_by_relavance_housing
    end
  end
  get ':search_type/related-items/:car_id' => 'related_items#index'
  get 'groups/:id' => 'car_groups#show', :as => 'car_groups'
  get ':type/topics' => 'products#topics'
  get 'my_feeds'  => 'contents#my_feeds'
  # Sample resource route (maps HTTP verbs to controller actions automatically):

  
resources :field_values, :only => [:create]
resources :answer_contents  

# get 'accounts/:username', :to => "accounts#index", :as => "accounts"


resources :accounts do
    member do
      # post :update_user
      put :change_password
      get :followers
      get :add_review
      get :add_information
      get :add_photo
    end
    collection do
      put :update
      get :profile
     end 
  end
  # match 'account_update', :to => "accounts#update", :as => "account_update", :via => [:put]
  get 'personal_deals', :to => "preferences#personal_deals"
 
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
   get 'create_buying_plan' => 'preferences#new'
   get 'preferences/:search_type/:uuid' => 'preferences#show'
   # get ':itemtype/guides/:guide_type' => 'contents#search_guide'
   # get ':itemtype/:item_id/guides/:guide_type' => 'contents#search_guide'
   
  resources :cars do
        resources :reports
        resources :shares
  end
   
  #put "/contents/update_guide" => 'contents#update_guide'

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
  get "/contents/search" => 'contents#search'
 
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

    collection do
      get "image_content_create"
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
  resources :laptops do
        resources :shares
  end  
  resources :bikes do
        resources :shares
  end   
  resources :cycles do
        resources :shares
  end
  resources :lens do
    resources :shares
  end
  resources :televisions do
    resources :shares
  end
  resources :wearable_gadgets do
    resources :shares
  end
  resources :consoles do
    resources :shares
  end
  resources :beauties do
    resources :shares
  end
  resources :countries do
    resources :shares
  end
  resources :states do
    resources :shares
  end
  resources :cities do
    resources :shares
  end
  resources :places do
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
  resources :lens do
    resources :reports
  end
  resources :televisions do
    resources :reports
  end
  resources :wearable_gadgets do
    resources :reports
  end
  resources :consoles do
    resources :reports
  end
  resources :beauties do
    resources :reports
  end
  resources :countries do
    resources :reports
  end
  resources :states do
    resources :reports
  end
  resources :cities do
    resources :reports
  end
  resources :places do
    resources :reports
  end
  resources :bike_groups
  resources :manufacturers
  resources :car_groups  
  resources :attribute_tags
  resources :topics
  resource :facebook, :except => :create do
    get :callback, :action => :create
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
      get :update_page
      get :update_redis
      get :remove_duplicate_item
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
  resources :processes, :only => [:index] do
    collection do
      get "item_update"
    end
  end


  post 'invitation/accept/:token' => "invitations#accept", :as => :accept_invitation
    
  resources :imageuploads, :only => [:show] 
  get "/imageuploads_tag" => 'imageuploads#tag'
  get "/autocomplete_tag" => 'imageuploads#autocomplete_tag'
   get "/messages/search_users" => 'messages#search_users'
   
  resources :messages
  post "/create_message/:id/:method" => 'messages#create_message', :as => :create_message
  post "/messages/block_user/:id" => 'messages#block_user', :as => :block_user
  post "/messages/:id/threaded" => 'messages#threaded_msg', :as => :threaded_msg

  
 # get '/:search_type', :to => "products#index"
  
  
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
 
  # root :to => 'home#index'
  root :to => 'home#targeting'

  get "/home" => 'home#index', :as => "home_products"
  #root :controller => :item, :action => :index
  # See how all your routes lay out with "rake routes"


  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  get ':controller(/:action(/:id(.:format)))'

  mount Resque::Server, :at => "/resque"

  get "travels/show_ads" => "travels#show_ads", :as => "travel_ads"
  get "travels/where_to_find_hotels",:to => "travels#where_to_find_hotels"
  get "travels/related_hotels",:to => "travels#related_hotels"

  get "sourceitems/load_suggestions" => "feeds#load_suggestions"

  get "admin/ad_reports" => "admin/ad_reports#index", :as => "admin_ad_reports"
  get "admin/ad_reports/report/:id" => "admin/ad_reports#report", :as => "admin_ad_reports_report"
  post "admin/ad_reports/generate_report" => "admin/ad_reports#generate_report", :as => "admin_ad_reports_generate"
  get "admin/widget_reports" => "admin/ad_reports#widget_reports", :as => "admin_widget_reports"
  get "admin/m_widget_reports" => "admin/ad_reports#m_widget_reports", :as => "admin_m_widget_reports"
  get "admin/more_reports" => "admin/ad_reports#more_reports", :as => "admin_more_reports"
  get "admin/more_reports_agg" => "admin/ad_reports#more_reports_agg", :as => "admin_more_reports_agg"
  get "ad_reports/load_vendors" => "admin/ad_reports#load_vendors", :as => "admin_load_vendors"
  get "admin/ad_reports/view_chart" => "admin/ad_reports#view_chart", :as => "admin_ad_report_chart"
  get "admin/ad_reports/widget_reports" => "admin/ad_reports#widget_reports", :as => "admin_ad_report_widget_reports"
  get "admin/ad_reports/view_ad_chart" => "admin/ad_reports#view_ad_chart", :as => "admin_ad_report_view_ad_chart"
  # get "admin/payment_reports" => "admin/ad_reports#payment_reports", :as => "admin_payment_reports"
  get "admin/user_and_items_reports" => "admin/ad_reports#user_and_items_reports", :as => "admin_user_and_items_reports"

  resources :feeds do
    collection do
      get "process_feeds"
      get "feed_urls"
      get 'feed_urls_batch_update'
      get "article_details"
      post "change_status"
      post "default_save"
      post "batch_update"
      post "change_category"
    end
  end


  resources :pixels do
    collection do
      get "pixel_matching"
      get "conv_track_pixel"
      get "un_matching_cookie"
      get 'vendor_page'
    end
  end

  delete"/delete_ad_image/:id" => "advertisements#delete_ad_image", :as => "delete_ad_image", :via => [:delete]
  get "advertisements/test_ads" => "advertisements#test_ads"
  get "advertisements/demo" => "advertisements#demo"
  get "advertisements/price_widget_demo" => "advertisements#price_widget_demo"
  get "advertisements/in_image_ads" => "advertisements#in_image_ads"
  get "advertisements/in_image_ads_demo" => "advertisements#in_image_ads_demo"
  get "advertisements/in_image_ads_demo_1" => "advertisements#in_image_ads_demo_1"
  get "advertisements/vendor_demo" => "advertisements#vendor_demo"
  get "advertisements/amazon_demo" => "advertisements#amazon_demo"
  get "advertisements/amazon_demo_type_5" => "advertisements#amazon_demo_type_5"
  get "advertisements/carwale_demo" => "advertisements#carwale_demo"
  get "advertisements/paytm_demo" => "advertisements#paytm_demo"
  get "advertisements/newcar_demo" => "advertisements#newcar_demo"
  get "advertisements/gaadi_demo" => "advertisements#gaadi_demo"
  get "advertisements/fashion_demo" => "advertisements#fashion_demo"
  get "advertisements/junglee_gadget_demo" => "advertisements#junglee_gadget_demo"
  get "advertisements/junglee_fashion_demo" => "advertisements#junglee_fashion_demo"
  get "advertisements/junglee_used_car_demo" => "advertisements#junglee_used_car_demo"
  get "advertisements/property_demo" => "advertisements#property_demo"
  get "advertisements/amazon_widget" => "advertisements#amazon_widget"
  get "advertisements/amazon_sports_widget" => "advertisements#amazon_sports_widget"
  get "advertisements/search_widget_via_iframe" => "advertisements#search_widget_via_iframe"
  get "advertisements/elec_widget_demo" => "advertisements#elec_widget_demo"
  get "advertisements/women_widget_demo" => "advertisements#women_widget_demo"
  get "advertisements/ad_via_iframe" => "advertisements#ad_via_iframe"
  get "advertisments/show_ads" => "advertisements#show_ads", :as => "show_ads"
  get "advertisments/check_user_details" => "advertisements#check_user_details", :as => "check_user_details"
  post "advertisments/get_user_details" => "advertisements#get_user_details", :as => "get_user_details", :via => [:post]
  get "advertisements/ab_test" => "advertisements#ab_test", :as => "advertisement_ab_test"
  post "advertisements/create_ab_settings" => "advertisements#create_ab_settings", :as => "create_ab_settings", :via => [:post]
  get "advertisements/video_ad_tracking" => "advertisements#video_ad_tracking", :as => "video_ad_tracking", :via => [:get]
  get "advertisements/video_ads" => "advertisements#video_ads", :as => "video_ads", :via => [:get]
  post "advertisements/ads_visited" => "advertisements#ads_visited", :via => [:post]
  get "advertisments/image_show_ads" => "advertisements#image_show_ads", :as => "image_show_ads"
  get "advertisements/get_adv_id" => "advertisements#get_adv_id", :as => "get_adv_id"
  get "/buy_at_best_price" => "products#buy_at_best_price", :as => "buy_at_best_price"
  get "/deal_widget_demo" => "products#deal_widget_demo", :as => "deal_widget_demo"

  post "/products/user_test_drive" => "products#user_test_drive", :as => "user_test_drive", :via => [:post]

  get "/admin/source_categories/edit" => "admin/source_categories#edit", :as => "edit_admin_source_category", :via => [:get]

  get "/reports/article_reports" => "reports#article_reports", :via => [:get]

  resources :plannto_user_details

  get "/pages/estore_plugin" => "pages#estore_plugin", :via => [:get]
  get "/pages/estore_search" => "pages#estore_search", :via => [:get]

  # get '/javascripts/plannto.elec_widget_1.js', :controller => :js, :action => :plannto_elec_widget_1_js, :format => :js, :as => :plannto_elec_widget_1_js

  get "/publishers" => "publishers#index", :via => [:get]

  # Removed actions
  # get "items/compare",:to => "dummy#index"
  get ':itemtype/guides/:guide_type' => "dummy#index"
  get ':itemtype/:item_id/guides/:guide_type' => "dummy#index"

  get '/:username', :to => "accounts#profile", :as => "profile"
end

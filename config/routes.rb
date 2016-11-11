Rails.application.routes.draw do


  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end


  root 'pages#home'

  devise_for :users, :controllers => { :omniauth_callbacks => "omniauth_callbacks", :registrations => "registrations" }

  post 'verifications/create' => 'verifications#create'
  get 'verifications/verify' => 'verifications#verify'
  post 'verifications/verify' => 'verifications#verify'

  get 'users' => 'users#index'
  get 'sub_users' => 'users#sub_users'
  get 'sub_users/:id' => 'users#sub_users'
  post 'sub_users' => 'users#sub_users_create'
  post 'sub_users/:id' => 'users#sub_users_create'
  get 'sub_users/delete/:id' => 'users#sub_users_delete'
  get 'sub_users/edit/:id' => 'users#sub_users_edit'
  patch 'sub_users/edit/:id' => 'users#sub_users_update'

  get 'flaged_comps/create/:id' => 'flaged_comps#create'
  get 'flaged_comps/delete'
  get 'flaged_comps/delete_comp'
  post 'flaged_comps/email/:id' => 'flaged_comps#email'
  get 'flaged_comps/email' => 'flaged_comps#email'

  get 'about-marketrex' => 'pages#about'
  get 'subscription-plans' => 'pages#plans'
  get 'marketrex-faqs' => 'pages#faqs'
  get 'about-leaserex' => 'pages#about_lease'

  resource :users

  get 'dashboard' => 'users#dashboard'
  ##get 'profile/:id' => 'users#show', :as => :public_profile




  get 'activity_log' => 'activity_log#index'
  match 'comp_requests/:direction', :to => 'comp_requests#index', :as => :comp_requests, :via => [:get]
  get 'comp_requests/:direction/:comp_type' => 'comp_requests#index'
  post 'comp_requests' => 'comp_requests#create'
  post 'comp_requests/remind' => 'comp_requests#remind'
  post 'comp_requests/update' => 'comp_requests#update'
  post 'delete_comp_requests' => 'comp_requests#destroy'




  match 'connection_requests/:direction', :to => 'connection_requests#index', :as => :connection_requests, :via => [:get]
  post 'connection_requests' => 'connection_requests#create', :as => :create_connection_requests
  post 'connection_requests/:request_id' => 'connection_requests#update'
  match 'delete_connection_requests/:id', :to => 'connection_requests#destroy', :as => :delete_connection_requests, :via => [:delete]
  get 'connection_request/accept/:id' => 'connection_requests#accept', :as => :accept_connection_request


  get 'connections' => 'connections#index'
  post 'connections' => 'connections#create'
  get 'connections/internal_create' => 'connections#create'
  match 'delete_connections/:id', :to => 'connections#destroy', :as => :delete_connections, :via => [:delete]

  resources :groups
  resources :back_end_lease_comps
  get 'back_end_lease_comps/create/:id/:temp' => 'back_end_lease_comps#create'
  resources :back_end_sale_comps
  get 'back_end_sale_comps/create/:id/:temp' => 'back_end_sale_comps#create'
  resources :back_end_custom_record
  get 'back_end_custom_record/create/:id/:temp/:custom_record_id' => 'back_end_custom_record#create'
  get 'back_end_custom_record/index/:id' => 'back_end_custom_record#index'
  resources :database_back_ends
  get 'database_back_ends' => 'database_back_ends#index'
  get 'uploader/database_back_ends' => 'database_back_ends#index'
  post 'database_back_ends/upload_image' => 'database_back_ends#upload_image'



=begin
  match 'messages/(:condition)', :to => 'messages#index', :as => :messages, :via => [:get]
  post 'message' => 'messages#create'
  post 'message/:message_id' => 'messages#forward'
=end






  get 'profile/update' => 'profile#update'
  get 'profile/update/:id' => 'profile#update'
  post 'profile/update' => 'profile#update'
  post 'profile/update/:id' => 'profile#update'
  post 'profile/picture' => 'profile#picture'
  post 'profile/picture/:id' => 'profile#picture'
  post 'profile/preferences' => 'profile#preferences'
  get 'profile/password' => 'profile#password'
  get 'profile/password/:id' => 'profile#password'
  post 'profile/password' => 'profile#password'
  post 'profile/password/:id' => 'profile#password'
  post 'profile/delete/:id' => 'profile#destroy'

  get 'profile/:id/(:request_id)' => 'users#show', :as => :public_profile

=begin
  get 'connections' => 'connections#index'
  post 'connections' => 'connections#index'

  post 'connections/ignore' => 'connections#ignore'
  post 'connections/accept' => 'connections#accept'
  post 'connections/add' => 'connections#add'
=end

  get 'messages' => 'messages#index'
  post 'messages' => 'messages#index'
  post 'messages/connections' => 'messages#connections'
  post 'messages/farword' => 'messages#farword'


  get 'activity_logs' => 'activity_logs#index'
  post 'activity_logs' => 'activity_logs#index'
  post 'activity_logs/update' => 'activity_logs#update'



  get "search/offices"
  get "search/basic"
  get "search/poll"
  get "search/fetch"
  post "search/advanced"
  
  get "search/advanced"

  get "search/simple"
  post "search/sales"

  get "search/address"
  
  post "search/industry"
  post "search/teams"
  post "search/lease_types"
  post "search/sixsigma"
  post "search/export"
  get "search/export"
  
  match 'search/lease_comp/(:id)' => 'search#lease_comp', :as => :search_lease_comp , :via => :get
  match 'search/sale_comp/(:id)' => 'search#sale_comp', :as => :search_sale_comp , :via => :get

  get "search/lease_comp_pdf/:id" => "search#lease_comp_pdf", :as => :search_lease_comp_pdf
  get "search/sale_comp_pdf/:id" => "search#sale_comp_pdf", :as => :search_sale_comp_pdf



  namespace :uploader do
    resources :tenant_records, only: [:index, :new, :create, :show] do
      match 'display_custom_record' => 'tenant_records#display_custom_record', via: :get
      match 'display_sales_comp' => 'tenant_records#display_sales_comp', via: :get
    end
    resources :import do
      collection do
        match 'process_file' => "import#process_file", via: :post
        match 'create_and_process_upload' => "import#create_and_process_upload", via: :post
        match 'marketrex_import_status' => 'import#import_status', :as => :marketrex_import_status, via: :get
      end
      member do
        get :filter_by_geocode
        get :filter_by_valid
        put :undo
      end
    end
    resources :ajax, only: [:opex_market_list, :market_expenses_list] do
      collection do
        match 'opex_type_list' => "ajax#opex_type_list", via: :get
        match 'property_type_list' => "ajax#property_type_list", via: :get
        match 'opex_market_list/:property_type_id' => "ajax#opex_market_list", via: :get
        match 'market_expenses_list/:opex_market_id' => "ajax#market_expenses_list", via: :get
        match 'get_custom_record_attributes/:custom_record_id' => "ajax#get_custom_record_attributes", via: :get
      end
    end
  end

end

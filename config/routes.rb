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




  get 'about-marketrex' => 'pages#about'
  get 'subscription-plans' => 'pages#plans'
  get 'marketrex-faqs' => 'pages#faqs'



  resource :users

  get 'dashboard' => 'users#dashboard'
  ##get 'profile/:id' => 'users#show', :as => :public_profile


  get 'activity_log' => 'activity_log#index'
  match 'comp_requests/:direction', :to => 'comp_requests#index', :as => :comp_requests, :via => [:get]
  post 'comp_requests' => 'comp_requests#create'
  post 'comp_requests/remind' => 'comp_requests#remind'
  post 'comp_requests/update' => 'comp_requests#update'
  post 'delete_comp_requests' => 'comp_requests#destroy'




  match 'connection_requests/:direction', :to => 'connection_requests#index', :as => :connection_requests, :via => [:get]
  post 'connection_requests' => 'connection_requests#create', :as => :create_connection_requests
  post 'connection_requests/:request_id' => 'connection_requests#update'
  match 'delete_connection_requests/:id', :to => 'connection_requests#destroy', :as => :delete_connection_requests, :via => [:delete]
  get 'connection_request/accept/:code' => 'connection_requests#accept', :as => :accept_connection_request


  get 'connections' => 'connections#index'
  post 'connections' => 'connections#create'
  match 'delete_connections/:id', :to => 'connections#destroy', :as => :delete_connections, :via => [:delete]


=begin
  match 'messages/(:condition)', :to => 'messages#index', :as => :messages, :via => [:get]
  post 'message' => 'messages#create'
  post 'message/:message_id' => 'messages#forward'
=end

















  get 'profile/update' => 'profile#update'
  post 'profile/update' => 'profile#update'
  post 'profile/picture' => 'profile#picture'
  post 'profile/preferences' => 'profile#preferences'
  get 'profile/password' => 'profile#password'
  post 'profile/password' => 'profile#password'

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

=begin
  get 'activity_logs' => 'activity_logs#index'
  post 'activity_logs' => 'activity_logs#index'
  post 'activity_logs/update' => 'activity_logs#update'

=end

  get "search/offices"
  get "search/basic"
  get "search/poll"
  get "search/fetch"
  post "search/advanced"
  
  get "search/advanced"
  
  post "search/industry"
  post "search/teams"
  post "search/lease_types"
  post "search/sixsigma"
  post "search/export"
  get "search/export"



end

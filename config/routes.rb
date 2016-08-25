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

  root 'common#index'

  devise_for :users, :controllers => { :omniauth_callbacks => "omniauth_callbacks" }

  post 'verifications/create' => 'verifications#create'
  get 'verifications/verify' => 'verifications#verify'
  post 'verifications/verify' => 'verifications#verify'

  get 'dashboard' => 'common#dashboard'

  get 'profile' => 'profile#index'
  get 'profile/update' => 'profile#update'
  post 'profile/update' => 'profile#update'
  post 'profile/picture' => 'profile#picture'

  post 'profile/preferences' => 'profile#preferences'

  get 'connections' => 'connections#index'
  post 'connections' => 'connections#index'

  post 'connections/ignore' => 'connections#ignore'
  post 'connections/accept' => 'connections#accept'
  post 'connections/add' => 'connections#add'

  get 'messages' => 'messages#index'
  post 'messages' => 'messages#index'
  post 'messages/connections' => 'messages#connections'
  post 'messages/farword' => 'messages#farword'

  get 'activity_logs' => 'activity_logs#index'
  post 'activity_logs' => 'activity_logs#index'
  post 'activity_logs/update' => 'activity_logs#update'


  get 'about-marketrex' => 'pages#about'
  get 'subscription-plans' => 'pages#plans'
  get 'marketrex-faqs' => 'pages#faqs'

end

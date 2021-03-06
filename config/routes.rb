FileManager::Application.routes.draw do

  root to: 'manager#index'

  get 'open' => 'manager#index', as: :open_files
  get 'open/*path' => 'manager#index', format: false

  get 'ls' => 'manager#ls', as: :list_files
  get 'ls/*path' => 'manager#ls', format: false

  post 'upload' => 'manager#upload', as: :upload_files
  post 'upload/*path' => 'manager#upload', format: false

  post 'mkdir/*path' => 'manager#mkdir', as: :make_directory, format: false
  post 'touch/*path' => 'manager#touch', as: :touch_file, format: false

  post 'duplicate/*path' => 'manager#duplicate', as: :duplicate_files, format: false

  put 'mv/*path' => 'manager#mv', as: :move_files, format: false

  put 'rename/*path' => 'manager#rename', as: :rename_files, format: false

  delete 'rm/*path' => 'manager#rm', as: :remove_files, format: false

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
end

EVEIndustrial::Application.routes.draw do
  root :to => 'static_pages#home'
  
  post 'spreadsheets/ice_mining'
  get  'spreadsheets/ice_mining'
  post 'spreadsheets/ore_mining'
  get  'spreadsheets/ore_mining'
  post 'spreadsheets/planetary_interaction'
  get  'spreadsheets/planetary_interaction'
  post 'spreadsheets/refining'
  get  'spreadsheets/refining'
  get  'static_pages/home'
  
  resources :ice_yields, only: [:index]
  resources :yields, only: [:index]
  resources :schematics, only: [:index]
  resources :ice_products, except: [:create, :new, :destroy]
  resources :ores, except: [:create, :new, :destroy]
  resources :planetary_commodities, except: [:create, :new, :destroy]
  resources :systems, except: [:create, :new, :destroy]
  
  resources :regions, except: [:create, :new, :destroy] do
    resources :systems
  end
  
  resources :minerals, except: [:create, :new, :destroy]  do
    collection do
      get 'check_eve_central_ids'
    end
  end
  
  resources :ice_ores, except: [:create, :new, :destroy] do
    member do
      get  'add_yields'
      post 'add_yields'
    end
  end
  
  resources :variations, except: [:create, :new, :destroy]  do
    collection do
      get 'check_central_ids'
    end
    member do
      get  'add_yields'
      post 'add_yields'
    end
  end
  
  # The priority is based upon order of creation:
  # first created -> highest priority.
  
  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action
  
  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)
  
  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products
  
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
  # root :to => 'welcome#index'
  
  # See how all your routes lay out with "rake routes"
end

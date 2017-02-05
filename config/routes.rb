Rails.application.routes.draw do
  resources :competences, only: [:index]

  resources :requirement_improvements, only: [:index] do
    collection do
      get 'teams_that_answered'
      get 'results_by_requirement'
      get 'count_by_requirement'
    end
  end

  resources :team_improvements, only: [:index, :show] do
    collection do
      get 'teams_comparison'
    end
  end

  resources :participant_improvements, only: [:index] do
    collection do
      get 'participants_comparison'
      get 'participants_comparison_independent'
    end
  end

  resources :correlations, only: [:index] do
    collection do
      get 'by_experiment'
    end
  end


  #get 'team_improvements/index'
  #get 'team_improvements/show/:id' => 'team_improvements#show'

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

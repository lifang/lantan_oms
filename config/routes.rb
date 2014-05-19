LantanOms::Application.routes.draw do
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


  resources :logins do
    collection do
      get :logout, :logout
      post :validate
    end
  end

  resources :stores do
    resources :welcomes
    resources :stations
    resources :customers do
      collection do
        get :add_car_get_datas, :print_orders, :show_order
        post :add_car_item
      end
    end
    resources :arrange_staffs
    resources :station_datas do
      collection do
        get :name_valid
      end
    end
    resources :roles do
      collection do
        post :role_name_valid, :set_auth_commit
        get :set_auth
      end
    end
    resources :set_stores do
      collection do
        get :search_cities
      end
    end
    resources :set_functions do
      collection do
        get :new_valid, :edit_valid, :del_position
        post :edit_position, :new_position
      end
    end
    resources :set_staffs
  end



  namespace :api do
    resources :orders do
      collection do
        get :index_list,:user_and_order,:order_details,:user_and_order,:search_car,:products_list,
          :new_index_list,:construction_site,:reservation_list,:complaint
      end
    end
  end
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
  root :to => "logins#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end

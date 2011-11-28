MongoShop::Application.routes.draw do
  resources :searches

  resources :manufacturers
  resources :categories do
    get "archive", :on => :member
  end
  resources :products

  devise_for :users

  root :to => "home#index"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end

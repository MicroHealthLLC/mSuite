Rails.application.routes.draw do
  root 'home#index'
  put 'mindmaps/destroy_nodes'  => 'mindmaps#destroy_nodes'
  get 'mindmaps/find_or_create' => 'mindmaps#find_or_create'
  get 'mindmaps/list_all_maps'  => 'mindmaps#list_all_maps'
  get 'nodes/hide_children'     => 'nodes#hide_children'

  resources :mindmaps do
    member do
      get :compute_child_nodes
      put :destroy_file
    end
  end
  
  resources :nodes do
    member do
      put :destroy_file
    end
  end
  
  mount ActionCable.server => '/cable'
end

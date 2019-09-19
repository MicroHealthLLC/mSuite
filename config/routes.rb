Rails.application.routes.draw do
  root 'home#index'
  put 'mindmaps/destroy_nodes'  => 'mindmaps#destroy_nodes'
  get 'mindmaps/find_or_create' => 'mindmaps#find_or_create'
  get 'nodes/hide_children'     => 'nodes#hide_children'

  resources :mindmaps
  resources :nodes
  
  mount ActionCable.server => '/cable'
end

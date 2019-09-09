Rails.application.routes.draw do
  root :to => redirect('/mindmaps/new')
  put 'mindmaps/destroy_nodes' => 'mindmaps#destroy_nodes'
  resources :mindmaps

  resources :nodes
  mount ActionCable.server => '/cable'
end

Rails.application.routes.draw do

  devise_for :users, controllers: { omniauth_callbacks: 'callbacks' }
  authenticate :user, lambda { |u| u.admin? } do
    begin
      ActiveAdmin.routes(self)
    rescue Exception => e
      puts "ActiveAdmin: #{e.class}: #{e}"
    end
  end

  put 'mindmaps/destroy_nodes' => 'mindmaps#destroy_nodes'
  get 'mindmaps/find_or_create' => 'mindmaps#find_or_create'
  get 'mindmaps/list_all_maps' => 'mindmaps#list_all_maps'
  get 'nodes/hide_children' => 'nodes#hide_children'

  resources :mindmaps, except: [:edit, :destroy] do
    member do
      get :compute_child_nodes
      put :destroy_file
      get :reset_mindmap
    end
  end

  resources :nodes, except: [:new, :edit, :show, :index] do
    member do
      put :update_export_order
      put :destroy_file
    end
  end

  mount ActionCable.server => '/cable'
  root 'home#index'
end

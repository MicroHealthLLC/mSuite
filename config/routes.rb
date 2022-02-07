Rails.application.routes.draw do

  devise_for :users, controllers: { omniauth_callbacks: 'callbacks' }
  authenticate :user, lambda { |u| u.admin? } do
    begin
      ActiveAdmin.routes(self)
    rescue Exception => e
      puts "ActiveAdmin: #{e.class}: #{e}"
    end
  end

  put 'msuite/destroy_nodes' => 'mindmaps#destroy_nodes'
  get 'msuite/list_all_maps' => 'mindmaps#list_all_maps'
  get 'nodes/hide_children' => 'nodes#hide_children'

  resources :mindmaps, path: 'msuite', except: [:edit] do
    member do
      get :compute_child_nodes
      put :destroy_file
      get :reset_mindmap
    end
  end

  resources :stages, except: [:new]

  resources :nodes, except: [:new, :edit, :show] do
    member do
      put :update_export_order
      put :destroy_file
    end
  end

  namespace :api, defaults: { format: :json } do
    get '/settings', to: 'settings#index'
    post '/settings', to: 'settings#update'
  end

  namespace :file_manager do
    get '/', to: 'mindmaps#index'
    resources :mindmaps, except: [:index, :new]
  end

  mount ActionCable.server => '/cable'
  root 'home#index'

  if Rails.env.production?
    get '*all', to: "not_found#index", constraints: -> (req) do
      req.path.exclude? 'rails/active_storage'
    end
  end
end

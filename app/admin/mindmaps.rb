ActiveAdmin.register Mindmap do
  actions :all, except: [:show]

  breadcrumb do
    links = [link_to('Admin', admin_root_path), link_to('Mindmaps', admin_mindmaps_path)]
    if %(show edit).include?(params['action'])
      links << link_to(mindmap.unique_key, edit_admin_mindmap_path)
    end
    links
  end

  permit_params do
    permitted = [
      :name,
      :unique_key,
      :user_id,
      :category_id,
      :status,
      :share,
      :permanent_lock,
      :description,
      :mm_type,
      shared_user_ids: []
    ]
  end

  form(html: { autocomplete: :off }) do |f|
    f.semantic_errors *f.object.errors.keys

    f.inputs 'Mindmap Details' do
      f.input :name
      f.input :mm_type
      f.input :unique_key, input_html: { disabled: true, :'data-id' => mindmap.id, autocomplete: :off }
      f.input :category
      f.input :status, include_blank: false, include_hidden: false, label: "State"
      f.input :share, include_blank: false, include_hidden: false, label: "Share as"
      f.input :permanent_lock
      f.input :description
      f.input :shared_users, label: "Shared with"
    end

    actions
  end

  index do
    selectable_column
    column :name
    column :unique_key
    column :mm_type
    column :category
    # column :description
    column "Creator", :user
    column "Shared with", :shared_users
    tag_column :status
    tag_column :share
    actions
  end

  controller do
    def create
      params[:mindmap][:user_id] = current_user.id
      super
    end
  end

  filter :name
  filter :unique_key
  filter :category
  filter :status, as: :select, collection: Mindmap.statuses
  filter :share, as: :select, collection: Mindmap.shares
  filter :user
end

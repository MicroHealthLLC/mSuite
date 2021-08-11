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
      :status,
      :description
    ]
  end

  form(html: { autocomplete: :off }) do |f|
    f.semantic_errors *f.object.errors.keys

    f.inputs 'Mindmap Details' do
      f.input :name
      f.input :unique_key
      f.input :user
      f.input :status
      f.input :description
    end

    actions
  end

  index do
    selectable_column
    column :name
    column :unique_key
    column :description
    column :user
    tag_column :status
    actions
  end

  filter :name
  filter :unique_key
  filter :status, as: :select, collection: Mindmap.statuses
end

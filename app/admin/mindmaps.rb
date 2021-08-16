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
      :description
    ]
  end

  form(html: { autocomplete: :off }) do |f|
    f.semantic_errors *f.object.errors.keys

    f.inputs 'Mindmap Details' do
      f.input :name
      f.input :unique_key, input_html: { disabled: mindmap.id?, :'data-id' => mindmap.id, autocomplete: :off }
      f.input :category
      f.input :user
      f.input :status, include_blank: false, include_hidden: false, label: "State"
      f.input :description
    end

    actions
  end

  index do
    selectable_column
    column :name
    column :unique_key
    column :category
    column :description
    column :user
    tag_column :status
    tag_column :share
    actions
  end

  filter :name
  filter :unique_key
  filter :category
  filter :status, as: :select, collection: Mindmap.statuses
end

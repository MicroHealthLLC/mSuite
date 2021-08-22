ActiveAdmin.register Category do
  actions :all, except: [:show]

  breadcrumb do
    links = [link_to('Admin', admin_root_path), link_to('Categories', admin_categories_path)]
    if %(show edit).include?(params['action'])
      links << link_to(category.id, edit_admin_category_path)
    end
    links
  end

  permit_params do
    permitted = [
      :name,
      :status
    ]
  end

  form(html: { autocomplete: :off }) do |f|
    f.semantic_errors *f.object.errors.keys

    f.inputs 'Category Details' do
      f.input :name
      f.input :status, include_blank: false, include_hidden: false, label: "State"
    end

    actions
  end

  index do
    selectable_column
    column :name
    tag_column :status
    actions
  end

  filter :name
  filter :status, as: :select, collection: Category.statuses
end

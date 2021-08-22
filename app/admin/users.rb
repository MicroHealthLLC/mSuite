ActiveAdmin.register User do
  actions :all, except: [:show]

  breadcrumb do
    links = [link_to('Admin', admin_root_path), link_to('Users', admin_users_path)]
    if %(show edit).include?(params['action'])
      links << link_to(user.email, edit_admin_user_path)
    end
    links
  end

  permit_params do
    permitted = [
      :email,
      :first_name,
      :last_name,
      :password,
      :password_confirmation,
      :status,
      :role
    ]
  end

  form(html: { autocomplete: :off }) do |f|
    f.semantic_errors *f.object.errors.keys

    f.inputs 'Basic Details' do

      f.input :first_name
      f.input :last_name
      f.input :email, input_html: { disabled: user.id?, :'data-id' => user.id, autocomplete: :off }
      f.input :password, input_html: { disabled: user.id?, autocomplete: :off }
      f.input :password_confirmation, input_html: { disabled: user.id?, autocomplete: :off }
      f.input :role, include_blank: false, include_hidden: false
      f.input :status, include_blank: false, include_hidden: false, label: 'State'
    end

    actions
  end

  index do
    selectable_column
    column :first_name
    column :last_name
    column :email
    tag_column :role
    tag_column :status
    actions
  end

  filter :email
  filter :first_name
  filter :last_name
  filter :status, as: :select, collection: User.statuses
end

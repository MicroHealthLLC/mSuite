# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

User.create_with(
  password: 'password',
  password_confirmation: 'password',
  first_name: 'admin',
  role: "superadmin",
  last_name: 'admin'
).find_or_create_by(email: 'admin@example.com')

setting = Setting.first_or_create

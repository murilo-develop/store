# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
if ENV["ADMIN_PASSWORD"].present? && ENV["ADMIN_EMAIL"].present?
  admin = User.find_or_initialize_by(email_address: ENV["ADMIN_EMAIL"])
  admin.password = ENV["ADMIN_PASSWORD"]
  admin.save!
  puts "Admin user ready: #{admin.email_address}"
else
  puts "ADMIN_EMAIL or ADMIN_PASSWORD not set, skipping admin seed"
end
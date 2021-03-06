# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
full_address_proc = Proc.new {"#{Faker::Address.street_address}, #{Faker::Address.city}"}

puts "Create admin account"
User.create! email: "admin@prx.com", password: "123456", role: :admin

puts "Create branch accounts & branches"
15.times do |i|
  user = User.create! email: "branch#{i+1}@prx.com", password: "123456", role: :branch
  working_time = "#{Faker::Number.between 6, 8}:#{["00", "30"].sample} ~ #{Faker::Number.between 17, 21}:#{["00", "30"].sample}"
  Branch.create! user: user,
    name: Faker::Company.name,
    address: full_address_proc.call,
    phone_number: Faker::PhoneNumber.cell_phone,
    working_time: working_time
end

puts "Create categories"
12.times do
  Category.create! name: Faker::Lorem.word,
    description: Faker::Lorem.paragraph
end

puts "Create products"
Category.all.each do |category|
  number_of_products = Faker::Number.between 10, 20
  number_of_products.times do
    category.products.create! name: Faker::Commerce.product_name,
      description: Faker::Lorem.paragraph,
      price: Faker::Commerce.price
  end
end

sample_branches = Branch.limit 5

puts "Create employees"
sample_branches.each do |branch|
  number_of_employees = Faker::Number.between 10, 20
  number_of_employees.times do
    branch.employees.create! id: SecureRandom.uuid,
      email: Faker::Internet.email,
      name: Faker::Name.name,
      gender: Employee.genders.keys.sample,
      phone_number: Faker::PhoneNumber.cell_phone,
      address: full_address_proc.call,
      role: Employee.roles.keys.sample
  end
end

puts "Create customers"
sample_branches.each do |branch|
  number_of_customers = Faker::Number.between 10, 20
  number_of_customers.times do
    level = Customer.levels.values.sample
    branch.customers.create! id: SecureRandom.uuid,
      email: Faker::Internet.email,
      name: Faker::Name.name,
      gender: Customer.genders.keys.sample,
      phone_number: Faker::PhoneNumber.cell_phone,
      address: full_address_proc.call,
      point: Faker::Number.between(level * 20, (level + 1) * 20 -1),
      level: level
  end
end

puts "Create branch_products"
products = Product.all
sample_branches.each do |branch|
  target_products = products.sample Faker::Number.between 30, 50
  target_products.each do |product|
    branch.branch_products.create! product: product,
      quantity: SecureRandom.random_number(100)
  end
end

puts "Create orders and order details"
sample_branches.each do |branch|
  employees = branch.employees.all
  branch_products = branch.branch_products.includes :product
  branch.customers.all.each do |customer|
    order_count = Faker::Number.between 1, 15
    order_count.times.each do
      order = branch.orders.build id: SecureRandom.uuid,
        customer: customer,
        employee: employees.sample,
        time: Faker::Time.between(7.days.ago, Time.zone.now, :day)
      # create order details
      total_price = 0
      branch_products.sample(Faker::Number.between 1, 5).each do |branch_product|
        order_detail = order.order_details.build id: SecureRandom.uuid,
          product_id: branch_product.product_id,
          quantity: Faker::Number.between(1, 5),
          unit_price: branch_product.product_price
        total_price += order_detail.quantity * order_detail.unit_price
      end
      order.assign_attributes total_price: total_price
      order.save!
    end
  end
end

puts "Create Synchronization Logs"
sample_branches.each do |branch|
  status = SynchronizationLog.statuses.keys.sample
  branch.synchronization_logs.create! status: status,
    content: "Synchronize branch data #{status}"
end

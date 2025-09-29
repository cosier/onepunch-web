# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding database..."

# Create demo users
user1 = User.find_or_create_by!(email: "demo@onepunch.app") do |u|
  u.password = "password123"
  u.first_name = "Demo"
  u.last_name = "User"
end

user2 = User.find_or_create_by!(email: "john@example.com") do |u|
  u.password = "password123"
  u.first_name = "John"
  u.last_name = "Doe"
  u.role = "user"
  u.last_sign_in_at = 1.hour.ago
end

user3 = User.find_or_create_by!(email: "jane@example.com") do |u|
  u.password = "password123"
  u.first_name = "Jane"
  u.last_name = "Smith"
  u.role = "admin"
  u.last_sign_in_at = 2.days.ago
end

puts "✅ Created users: #{user1.email}, #{user2.email}, #{user3.email}"

# Create demo organizations
org1 = Organization.find_or_create_by!(name: "Demo Company") do |o|
  o.slug = "demo-company"
  o.billing_email = "billing@democompany.com"
  o.timezone = "America/New_York"
  o.currency = "USD"
  o.industry = "technology"
  o.size = "small"
  o.onboarded_at = 1.month.ago
end

org2 = Organization.find_or_create_by!(name: "Creative Studio") do |o|
  o.slug = "creative-studio"
  o.billing_email = "hello@creative.com"
  o.timezone = "America/Los_Angeles"
  o.currency = "USD"
  o.industry = "design"
  o.size = "medium"
  o.onboarded_at = 2.weeks.ago
end

puts "✅ Created organizations: #{org1.name}, #{org2.name}"

# Create memberships - user1 is in both orgs
membership1 = Membership.find_or_create_by!(user: user1, organization: org1) do |m|
  m.role = "owner"
  m.joined_at = org1.created_at
end

membership2 = Membership.find_or_create_by!(user: user1, organization: org2) do |m|
  m.role = "admin"
  m.joined_at = 2.weeks.ago
end

# User2 and user3 in org1
membership3 = Membership.find_or_create_by!(user: user2, organization: org1) do |m|
  m.role = "admin"
  m.joined_at = 3.weeks.ago
end

membership4 = Membership.find_or_create_by!(user: user3, organization: org1) do |m|
  m.role = "member"
  m.joined_at = 1.week.ago
end

# Set current organizations
user1.update!(current_organization: org1) if user1.current_organization.nil?
user2.update!(current_organization: org1) if user2.current_organization.nil?
user3.update!(current_organization: org1) if user3.current_organization.nil?

# Use org1 for the rest of the seed data
org = org1
user = user1

puts "✅ Created memberships and set current organizations"

# Create demo clients
client1 = Client.find_or_create_by!(name: "Acme Corp", organization: org) do |c|
  c.email = "billing@acme.com"
  c.company = "Acme Corporation"
  c.phone = "+1-555-0123"
  c.address = "123 Business St, Suite 100\nBusiness City, BC 12345"
end

client2 = Client.find_or_create_by!(name: "TechStart Inc", organization: org) do |c|
  c.email = "accounts@techstart.com"
  c.company = "TechStart Incorporated"
  c.phone = "+1-555-0456"
  c.address = "456 Innovation Ave\nTech Valley, TV 67890"
end

puts "✅ Created clients: #{client1.name}, #{client2.name}"

# Create demo projects
project1 = Project.find_or_create_by!(name: "Website Redesign", organization: org) do |p|
  p.description = "Complete redesign of the company website with modern UI/UX"
  p.hourly_rate = 100
  p.color = "#10b981"
  p.status = "active"
  p.client = client1
end

project2 = Project.find_or_create_by!(name: "Mobile App Development", organization: org) do |p|
  p.description = "Native mobile app development for iOS and Android platforms"
  p.hourly_rate = 120
  p.color = "#3b82f6"
  p.status = "active"
  p.client = client2
end

project3 = Project.find_or_create_by!(name: "API Integration", organization: org) do |p|
  p.description = "Third-party API integrations and internal system connections"
  p.hourly_rate = 95
  p.color = "#8b5cf6"
  p.status = "active"
  p.client = client1
end

project4 = Project.find_or_create_by!(name: "Data Migration", organization: org) do |p|
  p.description = "Legacy system data migration to new platform"
  p.hourly_rate = 110
  p.color = "#ef4444"
  p.status = "completed"
  p.client = client2
end

puts "✅ Created projects: #{project1.name}, #{project2.name}, #{project3.name}, #{project4.name}"

# Create sample time entries
time_entries_data = [
  {
    project: project1,
    description: "Initial wireframes and mockups",
    started_at: 2.days.ago.beginning_of_day + 9.hours,
    duration: 3.hours.to_i,
    billable: true
  },
  {
    project: project1,
    description: "Homepage layout implementation",
    started_at: 2.days.ago.beginning_of_day + 14.hours,
    duration: 4.hours.to_i,
    billable: true
  },
  {
    project: project2,
    description: "Mobile app architecture planning",
    started_at: 1.day.ago.beginning_of_day + 10.hours,
    duration: 2.5.hours.to_i,
    billable: true
  },
  {
    project: project3,
    description: "API documentation review",
    started_at: 1.day.ago.beginning_of_day + 15.hours,
    duration: 1.5.hours.to_i,
    billable: false
  },
  {
    project: project2,
    description: "iOS development setup",
    started_at: Time.current.beginning_of_day + 9.hours,
    duration: 2.hours.to_i,
    billable: true
  },
  {
    project: project1,
    description: "Client feedback implementation",
    started_at: Time.current.beginning_of_day + 14.hours,
    duration: 1.hours.to_i,
    billable: true
  }
]

time_entries_data.each do |entry_data|
  started_at = entry_data[:started_at]
  ended_at = started_at + entry_data[:duration]

  TimeEntry.find_or_create_by!(
    user: user,
    project: entry_data[:project],
    started_at: started_at
  ) do |t|
    t.description = entry_data[:description]
    t.ended_at = ended_at
    t.duration = entry_data[:duration]
    t.billable = entry_data[:billable]
    t.billed = false
  end
end

puts "✅ Created #{time_entries_data.length} sample time entries"

# Create pending invitations
invitation1 = Invitation.find_or_create_by!(
  organization: org1,
  email: "newmember@example.com"
) do |i|
  i.role = "member"
  i.invited_by = user1
  i.token = SecureRandom.urlsafe_base64(32)
  i.expires_at = 7.days.from_now
end

invitation2 = Invitation.find_or_create_by!(
  organization: org2,
  email: "designer@example.com"
) do |i|
  i.role = "admin"
  i.invited_by = user1
  i.token = SecureRandom.urlsafe_base64(32)
  i.expires_at = 7.days.from_now
end

puts "✅ Created pending invitations"

# Summary
total_time = TimeEntry.sum(:duration)
billable_time = TimeEntry.billable.sum(:duration)

puts ""
puts "🎉 Database seeding completed!"
puts "📊 Summary:"
puts "   - Users: #{User.count}"
puts "   - Organizations: #{Organization.count}"
puts "   - Memberships: #{Membership.count}"
puts "   - Projects: #{Project.count} (#{Project.active.count} active)"
puts "   - Clients: #{Client.count}"
puts "   - Time Entries: #{TimeEntry.count}"
puts "   - Invitations: #{Invitation.count} pending"
puts "   - Total Time Tracked: #{ApplicationController.helpers.format_duration(total_time)}"
puts "   - Billable Time: #{ApplicationController.helpers.format_duration(billable_time)}"
puts ""
puts "🚀 Test Accounts:"
puts "   - demo@onepunch.app / password123 (Owner of Demo Company + Admin of Creative Studio)"
puts "   - john@example.com / password123 (Admin of Demo Company)"
puts "   - jane@example.com / password123 (Member of Demo Company)"
puts ""
puts "📌 Use Cmd+K to quickly switch between organizations!"

# app/controllers/admin/dashboard_controller.rb
class Admin::DashboardController < Admin::BaseController
  def index
    @stats = {
      total_users: User.count,
      active_users: User.active.count,
      total_organizations: Organization.count,
      personal_orgs: Organization.personal.count,
      business_orgs: Organization.business.count,
      total_projects: Project.count,
      total_time_entries: TimeEntry.count,
      total_invoices: Invoice.count
    }

    @recent_users = User.order(created_at: :desc).limit(10)
    @recent_organizations = Organization.order(created_at: :desc).limit(10)
  end
end
module OnboardingRequirement
  extend ActiveSupport::Concern

  # Check if user has completed all setup requirements
  def setup_complete?
    asana_connected? && first_project_created?
  end

  # Individual requirement checks
  def asana_connected?
    # TODO: Implement after Asana integration
    # asana_credential.present? && asana_credential.valid_token?
    false
  end

  def first_project_created?
    current_organization&.projects&.exists?
  end

  # Get list of incomplete requirements for display
  def incomplete_requirements
    requirements = []
    requirements << { name: "Connect Asana", completed: asana_connected?, path: "#" } unless asana_connected?
    requirements << { name: "Create first project", completed: first_project_created?, path: "/projects/new" } unless first_project_created?
    requirements
  end

  # Get completion percentage
  def setup_completion_percentage
    total = 2
    completed = [asana_connected?, first_project_created?].count(true)
    (completed.to_f / total * 100).round
  end
end
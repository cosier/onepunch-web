class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_onboarded

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(organization_params)

    if @organization.save
      # Create membership with owner role
      @organization.add_member(current_user, role: 'owner')

      # Set as current organization
      current_user.update!(current_organization: @organization)

      respond_to do |format|
        format.html { redirect_to dashboard_path, notice: "Welcome to #{@organization.name}!" }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # For multi-step wizard updates
    # This can be enhanced based on the specific step
    head :ok
  end

  def complete
    if current_user.current_organization
      current_user.current_organization.complete_onboarding!
      redirect_to dashboard_path, notice: "Onboarding completed successfully!"
    else
      redirect_to new_onboarding_path, alert: "Please complete the onboarding process."
    end
  end

  private

  def redirect_if_onboarded
    if !current_user.needs_onboarding? && current_user.current_organization&.onboarded?
      redirect_to dashboard_path
    end
  end

  def organization_params
    params.require(:organization).permit(:name, :website, :industry, :size, :timezone, :currency)
  end
end

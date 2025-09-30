class OrganizationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization, only: [:show, :update, :destroy]
  before_action :authorize_admin!, only: [:update, :destroy]

  def index
    @organizations = current_user.organizations
  end

  def show
  end

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(organization_params)

    if @organization.save
      # Add current user as owner
      @organization.add_member(current_user, role: 'owner')
      # Switch to new organization
      current_user.switch_organization!(@organization)
      redirect_to dashboard_path, notice: 'Organization created successfully!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @organization.update(organization_params)
      respond_to do |format|
        format.html { redirect_to organization_path(@organization), notice: 'Organization updated successfully!' }
        format.turbo_stream {
          flash.now[:notice] = 'Saved!'
          render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_notice")
        }
      end
    else
      respond_to do |format|
        format.html { redirect_to organization_path(@organization), alert: 'Failed to update organization' }
        format.turbo_stream {
          flash.now[:alert] = @organization.errors.full_messages.join(', ')
          render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_alert")
        }
      end
    end
  end

  def destroy
    if @organization.personal?
      redirect_to organizations_path, alert: 'Cannot delete personal organization'
      return
    end

    @organization.destroy
    redirect_to organizations_path, notice: 'Organization deleted successfully'
  end

  private

  def set_organization
    @organization = current_user.organizations.find(params[:id])
  end

  def authorize_admin!
    unless current_user.admin_of?(@organization)
      redirect_to root_path, alert: 'You are not authorized to perform this action'
    end
  end

  def organization_params
    params.require(:organization).permit(:name)
  end
end

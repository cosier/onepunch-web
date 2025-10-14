# app/controllers/settings/api_tokens_controller.rb
class Settings::ApiTokensController < ApplicationController
  before_action :authenticate_user!
  before_action :set_api_token, only: [:destroy]

  # GET /settings/api_tokens (Turbo Frame)
  def index
    @api_tokens = current_user.api_tokens.recent
  end

  # GET /settings/api_tokens/new (Turbo Frame modal)
  def new
    @api_token = current_user.api_tokens.build
  end

  # POST /settings/api_tokens
  def create
    @api_token = current_user.api_tokens.build(api_token_params)

    # Check token limit (max 10 per user)
    if current_user.api_tokens.active.count >= 10
      respond_to do |format|
        format.html { redirect_to settings_account_path, alert: "Maximum of 10 active tokens allowed." }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "api_token_modal",
            partial: "settings/api_tokens/error",
            locals: { message: "Maximum of 10 active tokens allowed." }
          )
        end
      end
      return
    end

    if @api_token.save
      # Store the token for one-time display
      @new_token = @api_token.token

      respond_to do |format|
        format.html { redirect_to settings_api_token_path(@api_token), notice: "API token created successfully." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "api_token_modal",
            partial: "settings/api_tokens/form",
            locals: { api_token: @api_token }
          )
        end
      end
    end
  end

  # GET /settings/api_tokens/:id (one-time token view after creation)
  def show
    # This is only accessible immediately after creation via turbo stream
    # We don't store the plain token, so redirect if trying to access directly
    redirect_to settings_account_path
  end

  # DELETE /settings/api_tokens/:id
  def destroy
    @api_token.revoke!

    respond_to do |format|
      format.html { redirect_to settings_account_path, notice: "API token revoked successfully." }
      format.turbo_stream
    end
  end

  private

  def set_api_token
    @api_token = current_user.api_tokens.find(params[:id])
  end

  def api_token_params
    params.require(:api_token).permit(:name, :expires_at)
  end
end

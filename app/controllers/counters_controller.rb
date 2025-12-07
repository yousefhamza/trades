class CountersController < ApplicationController
  skip_forgery_protection if: -> { request.format.json? }
  before_action :authenticate_user!
  before_action :set_counter, only: [:show, :edit, :update, :destroy, :increment, :share_to_slack]

  def index
    @counters = current_user.counters

    respond_to do |format|
      format.html
      format.json { render json: @counters }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @counter }
    end
  end

  def new
    @counter = current_user.counters.build
  end

  def create
    @counter = current_user.counters.build(counter_params)

    respond_to do |format|
      if @counter.save
        format.html { redirect_to @counter, notice: "Counter was successfully created." }
        format.json { render json: @counter, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @counter.errors }, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @counter.update(counter_params)
        format.html { redirect_to @counter, notice: "Counter was successfully updated." }
        format.json { render json: @counter }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @counter.errors }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @counter.destroy

    respond_to do |format|
      format.html { redirect_to counters_path, notice: "Counter was successfully deleted." }
      format.json { head :no_content }
    end
  end

  def increment
    @counter.increment!

    respond_to do |format|
      format.html { redirect_to @counter, notice: "Counter incremented!" }
      format.json { render json: @counter }
    end
  end

  def share_to_slack
    if SlackService.new.share_counter(@counter)
      redirect_back fallback_location: @counter, notice: "Counter shared to Slack!"
    else
      redirect_back fallback_location: @counter, alert: "Failed to share to Slack. Check your Slack configuration."
    end
  end

  private

  def set_counter
    @counter = current_user.counters.find(params[:id])
  end

  def counter_params
    params.require(:counter).permit(:name)
  end
end

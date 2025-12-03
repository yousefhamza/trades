class Api::CountersController < Api::BaseController
  before_action :set_counter, only: [:show, :update, :destroy, :increment]

  def index
    @counters = current_user.counters
    render json: @counters
  end

  def show
    render json: @counter
  end

  def create
    @counter = current_user.counters.build(counter_params)

    if @counter.save
      render json: @counter, status: :created
    else
      render json: { errors: @counter.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @counter.update(counter_params)
      render json: @counter
    else
      render json: { errors: @counter.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @counter.destroy
    head :no_content
  end

  def increment
    @counter.increment!
    render json: @counter
  end

  private

  def set_counter
    @counter = current_user.counters.find(params[:id])
  end

  def counter_params
    params.require(:counter).permit(:name)
  end
end

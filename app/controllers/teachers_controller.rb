class TeachersController < ApplicationController
  before_action :set_teacher, only: [:show, :edit, :update, :destroy]
  def index
    @grid = TeachersGrid.new(grid_params) do |scope|
      scope.page(params[:page])
    end
  end

  def grid_params
    params.fetch(:teachers_grid, {}).permit!
  end
  # GET /teachers
  # GET /teachers.json
  #def index
  #  @teachers = Teacher.all
  #end

  # GET /teachers/1
  # GET /teachers/1.json
  def show
    @schedules=@teacher.get_schedules
  end

  # GET /teachers/new
  def new
    @teacher = Teacher.new
  end

  # GET /teachers/1/edit
  def edit
  end

  # POST /teachers
  # POST /teachers.json
  def create
    @teacher = Teacher.new(teacher_params)

    respond_to do |format|
      if @teacher.save
        @teacher.update_custo_in_teacher_matter(teacher_params[:matter_ids])
        format.html { redirect_to @teacher, notice: 'Teacher was successfully created.' }
        format.json { render :show, status: :created, location: @teacher }
      else
        format.html { render :new }
        format.json { render json: @teacher.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /teachers/1
  # PATCH/PUT /teachers/1.json
  def update
    respond_to do |format|
      if @teacher.update(teacher_params)
        @teacher.update_custo_in_teacher_matter(teacher_params[:matter_ids])
        format.html { redirect_to @teacher, notice: 'Teacher was successfully updated.' }
        format.json { render :show, status: :ok, location: @teacher }
      else
        format.html { render :edit }
        format.json { render json: @teacher.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /teachers/1
  # DELETE /teachers/1.json
  def destroy
    if @teacher.destroy
      respond_to do |format|
        format.html { redirect_to teachers_url, notice: 'Teacher was successfully destroyed.' }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to teachers_url, notice: 'Teacher was not destroyed (references ?).' }
        format.json { head :no_content }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_teacher
    @teacher = Teacher.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def teacher_params
    params.require(:teacher).permit(:name,:email,:person_status, :firstname, :lastname, :adress, :postalcode, :town, :birthday,
    {:matter_ids=>[]}, :description, :custo)
  end
end

class OresController < ApplicationController
  # GET /ores
  # GET /ores.json
  def index
    @ores = Ore.all
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @ores }
    end
  end
  
  # GET /ores/1
  # GET /ores/1.json
  def show
    @ore = Ore.find(params[:id])
    @shares = []
    variation = @ore.variations.first
    total = variation.yields.sum(:quantity)
    
    variation.minerals.each do |mineral|
      y = variation.yields.detect { |y| y[:mineral_id] == mineral.id }
      share = { :mineral => mineral, :percentage => (y.quantity / total.to_f) * 100 }
      @shares << share
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @ore }
    end
  end
  
  # GET /ores/new
  # GET /ores/new.json
  def new
    @ore = Ore.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @ore }
    end
  end
  
  # GET /ores/1/edit
  def edit
    @ore = Ore.find(params[:id])
  end
  
  # PUT /ores/1
  # PUT /ores/1.json
  def update
    @ore = Ore.find(params[:id])
    
    respond_to do |format|
      if @ore.update_attributes(params[:ore])
        format.html { redirect_to @ore, notice: 'Ore was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @ore.errors, status: :unprocessable_entity }
      end
    end
  end
end

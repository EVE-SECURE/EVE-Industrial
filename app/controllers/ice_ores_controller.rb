class IceOresController < ApplicationController
  skip_before_filter :is_admin, only: [:index, :show]
  
  # GET /ice_ores/check_central_ids
  def check_central_ids
    @results = []
    IceOre.all.each do |ice_ore|
      request = 'http://api.eve-central.com/api/quicklook?typeid=%s' % [ice_ore.central_id]
      xml = Curl.get(request).body_str
      xml_doc  = Nokogiri::XML(xml)
      ec_name = xml_doc.xpath('/evec_api/quicklook/itemname').text
      result = { :name => ice_ore.name, :ec_name => ec_name, :match => ice_ore.name == ec_name }
      @results << result
    end
  end
  
  # GET /ice_ores/1/add_yields
  # POST /ice_ores/1/add_yields
  def edit_yields
    @ore = IceOre.find(params[:id])
    @products = IceProduct.all
    @yields = @ore.ice_yields
    
    if request.request_method == 'POST'
      @products.each do |product|
        y = IceYield.find_by_ice_product_id_and_ice_ore_id(product.id, @ore.id)
        if params[product.id.to_s] == ''
          y.destroy unless y.nil?
        else
          y = IceYield.new if y.nil?
          y.quantity = params[product.id.to_s]
          y.ice_ore = @ore
          y.ice_product = product
          y.save
        end
      end
      redirect_to @ore, :notice => 'Yields updated successfully'
    end
  end
  
  # GET /ice_ores
  # GET /ice_ores.json
  def index
    @ice_ores = IceOre.all
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @ice_ores }
    end
  end
  
  # GET /ice_ores/1
  # GET /ice_ores/1.json
  def show
    @ice_ore = IceOre.find(params[:id])
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @ice_ore }
    end
  end
  
  # GET /ice_ores/1/edit
  def edit
    @ice_ore = IceOre.find(params[:id])
  end
  
  # PUT /ice_ores/1
  # PUT /ice_ores/1.json
  def update
    @ice_ore = IceOre.find(params[:id])
    
    respond_to do |format|
      if @ice_ore.update_attributes(params[:ice_ore])
        format.html { redirect_to @ice_ore, notice: 'Ice ore was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @ice_ore.errors, status: :unprocessable_entity }
      end
    end
  end
end

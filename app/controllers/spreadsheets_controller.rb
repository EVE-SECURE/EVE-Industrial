class SpreadsheetsController < ApplicationController
  require 'nokogiri'
  
  def planetary_interaction
    if (params.has_key? :region) && !params[:region].empty?
      items = PlanetaryCommodity.pluck :central_id
      
      # Get data from EVE-Central
      if params[:system].empty?
        prices = request_prices items, params[:region], :region
      else
        prices = request_prices items, params[:system], :system
      end
      
      # Retrieve user specific data
      market_tax = params[:market_tax].to_f
      customs_office_tax = params[:customs_office_tax].to_f
      processors = { }
      processors[1] = params[:basic_processors].to_i
      processors[2] = params[:advanced_processors].to_i
      processors[3] = params[:advanced_processors].to_i
      processors[4] = params[:high_tech_processors].to_i
      
      # Save in cookies
      save_location_values
      cookies[:basic_processors] = params[:basic_processors]
      cookies[:advanced_processors] = params[:advanced_processors]
      cookies[:high_tech_processors] = params[:high_tech_processors]
      cookies[:market_tax] = params[:market_tax]
      cookies[:customs_office_tax] = params[:customs_office_tax]
      
      @materials = []
      PlanetaryCommodity.where(:tier => 1).each do |pc|
        material = { :name => pc.name, :id => pc.id }
        material[:revenue] = pc.hour_revenue prices[:buy][pc.central_id], processors
        material[:inversion_return] = pc.processing_revenue prices, customs_office_tax, market_tax
        resource = pc.schematics[0].input
        material[:resource] = { :name => resource.name, :id => resource.id, :price => prices[:buy][resource.central_id] }
        @materials << material
      end
      @commodities = []
      PlanetaryCommodity.where(:tier => 2).each do |pc|
        resource = { :name => pc.name, :id => pc.id }
        resource[:revenue] = pc.hour_revenue prices[:buy][pc.central_id], processors
        resource[:inversion_return] = pc.processing_revenue prices, customs_office_tax, market_tax
        @commodities << resource
      end
    end
    
    set_location_values
    @basic_processors = cookies[:basic_processors]
    @advanced_processors = cookies[:advanced_processors]
    @high_tech_processors = cookies[:high_tech_processors]
    @market_tax = cookies[:market_tax]
    @customs_office_tax = cookies[:customs_office_tax]
  end
  
  def refining
    if (params.has_key? :region) && !params[:region].empty?
      items = Variation.pluck(:central_id).concat(Mineral.pluck :central_id)
      
      # Retrieve user specific data
      station_yield = params[:station_yield]
      refinery_tax = params[:refinery_tax]
      market_tax = params[:market_tax]
      skills = { :special_processing_skills => {} }
      skills[:refining_skill] = params[:refining_skill]
      skills[:refinery_efficiency_skill] = params[:refinery_efficiency_skill]
      params[:processing_skills].each do |k,v|
        skill_name = '%s_processing_skill' % k
        skills[k] = v
        cookies[skill_name] = v # Also save to cookie
      end
      
      # Save in cookies
      save_location_values
      cookies[:refinery_tax] = params[:refinery_tax]
      cookies[:market_tax] = params[:market_tax]
      cookies[:station_yield] = params[:station_yield]
      cookies[:refining_skill] = params[:refining_skill]
      cookies[:refinery_efficiency_skill] = params[:refinery_efficiency_skill]
      
      # Get data from EVE-Central
      if params[:system].empty?
        prices = request_prices items, params[:region], :region
      else
        prices = request_prices items, params[:system], :system
      end
      
      @minerals = []
      Mineral.all.each do |min|
        mineral = { :id => min.id, :name => min.name }
        mineral[:price] = prices[:buy][min.central_id]
        @minerals << mineral
      end
      
      # Retrieve the information to show about each ore variation
      @variations = []
      Variation.all.each do |var|
        variation = { :id => var.id, :name => var.name }
        variation[:price] = prices[:sell][var.central_id]
        refining_results = var.refine_revenue prices, station_yield, skills, refinery_tax
        variation[:efficiency] = refining_results[:efficiency]
        if variation[:price] == 0
          variation[:refine_revenue] = -100 # lower than any possible value
        else
          cost = var.raw_revenue prices[:sell][var.central_id]
          profit = refining_results[:revenue] * (1 - market_tax.to_f/100)
          profit -= cost
          profit /= cost
          variation[:refine_revenue] = profit
        end
        @variations << variation
      end
    end
    
    # Set initial values for input fields
    set_location_values
    @ores = Ore.all
    @station_yield = cookies[:station_yield]
    @refining_skill = cookies[:refining_skill]
    @refinery_efficiency_skill = cookies[:refinery_efficiency_skill]
    @refinery_tax = cookies[:refinery_tax]
    @market_tax = cookies[:market_tax]
    @processing_skills = {}
    @ores.each do |o|
      skill_name = '%s_processing_skill' % o.name
      @processing_skills[o.id] = cookies[skill_name]
    end
  end
  
  def ore_mining
    if (params.has_key? :region) && !params[:region].empty?
      items = Variation.pluck(:central_id).concat(Mineral.pluck :central_id)
      
      # Retrieve user specific data
      station_yield = params[:station_yield]
      refinery_tax = params[:refinery_tax]
      skills = { :special_processing_skills => {} }
      skills[:refining_skill] = params[:refining_skill]
      skills[:refinery_efficiency_skill] = params[:refinery_efficiency_skill]
      params[:processing_skills].each do |k,v|
        skill_name = '%s_processing_skill' % k
        skills[k] = v
        cookies[skill_name] = v # Also save to cookie
      end
      
      # Save in cookies
      save_location_values
      cookies[:refinery_tax] = params[:refinery_tax]
      cookies[:station_yield] = params[:station_yield]
      cookies[:refining_skill] = params[:refining_skill]
      cookies[:refinery_efficiency_skill] = params[:refinery_efficiency_skill]
      
      # Get data from EVE-Central
      if params[:system].empty?
        prices = request_prices items, params[:region], :region
      else
        prices = request_prices items, params[:system], :system
      end
      
      # Retrieve the information to show about each ore variation
      @variations = []
      Variation.all.each do |var|
        variation = { :id => var.id, :name => var.name }
        variation[:price] = prices[:buy][var.central_id]
        variation[:raw_revenue] = var.raw_revenue(prices[:buy][var.central_id])
        refining_results = var.refine_revenue(prices[:buy], station_yield, skills, refinery_tax)
        variation[:refine_revenue] = refining_results[:revenue]
        variation[:refine_yield] = refining_results[:yield]
        variation[:volume] = refining_results[:volume]
        if variation[:price] == 0
          variation[:refining_gain] = 0
        else
          variation[:refining_gain] = (variation[:refine_revenue] / variation[:raw_revenue] - 1) * 100
        end
        @variations << variation
      end
    end
    
    # Set initial values for input fields
    set_location_values
    @ores = Ore.all
    @station_yield = cookies[:station_yield]
    @refining_skill = cookies[:refining_skill]
    @refinery_efficiency_skill = cookies[:refinery_efficiency_skill]
    @refinery_tax = cookies[:refinery_tax]
    @processing_skills = {}
    @ores.each do |o|
      skill_name = '%s_processing_skill' % o.name
      @processing_skills[o.id] = cookies[skill_name]
    end
  end
  
  def ice_mining
    if (params.has_key? :region) && !params[:region].empty?
      items = IceProduct.pluck(:central_id).concat(IceOre.pluck :central_id)
      
      # Retrieve user specific data
      station_yield = params[:station_yield]
      refinery_tax = params[:refinery_tax]
      skills = { }
      skills[:refining_skill] = params[:refining_skill]
      skills[:refinery_efficiency_skill] = params[:refinery_efficiency_skill]
      skills[:ice_processing_skill] = params[:ice_processing_skill]
      
      # Save in cookies
      save_location_values
      cookies[:refinery_tax] = params[:refinery_tax]
      cookies[:station_yield] = params[:station_yield]
      cookies[:refining_skill] = params[:refining_skill]
      cookies[:refinery_efficiency_skill] = params[:refinery_efficiency_skill]
      cookies[:ice_processing_skill] = params[:ice_processing_skill]
      
      # Get data from EVE-Central
      if params[:system].empty?
        prices = request_prices items, params[:region], :region
      else
        prices = request_prices items, params[:system], :system
      end
      
      # Retrieve the information to show about each ore variation
      @ores = []
      IceOre.all.each do |ore|
        ore_hash = { :id => ore.id, :name => ore.name }
        ore_hash[:price] = prices[:buy][ore.central_id]
        refining_results = ore.refine_revenue(prices[:buy], station_yield, skills, refinery_tax)
        ore_hash[:refine_revenue] = refining_results[:revenue]
        ore_hash[:refine_yield] = refining_results[:yield]
        ore_hash[:volume] = refining_results[:volume]
        if ore_hash[:price] == 0
          ore_hash[:refining_gain] = 0
        else
          ore_hash[:refining_gain] = (ore_hash[:refine_revenue] / ore_hash[:price] - 1) * 100
        end
        @ores << ore_hash
      end
    end
    
    # Set initial values for input fields
    set_location_values
    @station_yield = cookies[:station_yield]
    @refining_skill = cookies[:refining_skill]
    @refinery_efficiency_skill = cookies[:refinery_efficiency_skill]
    @ice_processing_skill = cookies[:refinery_efficiency_skill]
    @refinery_tax = cookies[:refinery_tax]
  end
  
  private
  
  # Returns a hash with :buy / :sell prices percentiles and market volume
  def request_prices (item_ids_array, location_id, location_type)
    # Construct the necessary request URL
    items = item_ids_array.join(',')
    if location_type == :region
      region = Region.find location_id
      request = 'http://api.eve-central.com/api/marketstat?typeid=%s&regionlimit=%s' % [items, region.central_id]
    elsif location_type == :system
      system = System.find location_id
      request = 'http://api.eve-central.com/api/marketstat?typeid=%s&usesystem=%s' % [items, system.central_id]
    else
      raise 'Unknown location type'
    end
    
    # Request data and get back the results
    xml = Curl.get(request).body_str
    xml_doc = Nokogiri::XML(xml)
    buy_percentiles = xml_doc.xpath('/evec_api/marketstat/type/buy/percentile')
    sell_percentiles = xml_doc.xpath('/evec_api/marketstat/type/sell/percentile')
    
    # Dump data from the XML into two hashes
    buy_prices = { }
    sell_prices = { }
    buy_percentiles.each do |percentile|
      item_id = percentile.parent.parent['id'].to_i
      buy_prices[item_id] = percentile.text.to_f
    end
    sell_percentiles.each do |percentile|
      item_id = percentile.parent.parent['id'].to_i
      sell_prices[item_id] = percentile.text.to_f
    end
    
    { :buy => buy_prices, :sell => sell_prices }
  end
  
  # Sets previously used location as default
  def set_location_values
    @regions = Region.all
    @region = cookies[:region]
    @systems = @region.nil? ? nil : Region.find(@region).systems
    @system = cookies[:system]
    nil
  end
  
  # Saves location requested to cookies
  def save_location_values
    cookies[:region] = params[:region]
    cookies[:system] = params[:system]
    nil
  end
end

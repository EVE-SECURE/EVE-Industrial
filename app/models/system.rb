class System < ActiveRecord::Base
  attr_accessible :central_id, :name, :region_id
  
  belongs_to :region
end

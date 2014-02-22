# == Schema Information
#
# Table name: yields
#
#  id           :integer          not null, primary key
#  quantity     :integer
#  variation_id :integer
#  mineral_id   :integer
#

class Yield < ActiveRecord::Base
  attr_accessible :bonus, :mineral_id, :quantity, :variation_id
  
  belongs_to :mineral
  belongs_to :variation
  
  default_scope { order('id') }
  
  def base_yield
    quantity / variation.refine_volume
  end
end

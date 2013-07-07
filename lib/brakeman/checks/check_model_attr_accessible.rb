require 'brakeman/checks/base_check'

# Author: Paul Deardorff (themetric) 
# Checks models to see if important foreign keys 
# or attributes are exposed as attr_accessible when 
# they probably shouldn't be. 

class Brakeman::CheckModelAttrAccessible < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Reports models which have dangerous attributes defined under the attr_accessible whitelist."

  SUSP_ATTRS = {
    /admin/ => CONFIDENCE[:high], # Very dangerous unless some Rails authorization used 
    /role/ => CONFIDENCE[:med],   
    :account_id => CONFIDENCE[:high], 
    /\S*_id(s?)\z/ => CONFIDENCE[:low] # All other foreign keys have weak/low confidence 
  }

  def run_check
    check_models do |name, model|
      accessible_attrs = model[:attr_accessible]
      accessible_attrs.each do |attribute|
        SUSP_ATTRS.each do |susp_attr, confidence|
            if susp_attr.is_a?(Regexp) and susp_attr =~ attribute.to_s or susp_attr == attribute 
              warn :model => name,    
                :file => model[:file],                          
                :warning_type => "Mass Assignment", 
                :warning_code => :mass_assign_call,
                :message => "Please check and protect #{attribute} attribute defined under attr_accessible.", 
                :confidence => confidence 
              break # Prevent from matching single attr multiple times
            end 
        end         
      end 
    end
  end

  def check_models
    tracker.models.each do |name, model|
      if !model[:attr_accessible].nil?
        yield name, model
      end
    end
  end
 
end

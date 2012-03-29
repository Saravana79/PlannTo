class FieldValuesController < ApplicationController
  def create
    params['field_value'].each do |k,v|
   		@field_value = FieldValue.new(:field_id => k, :value => v)
      @field_value.save
    end
 		respond_to do |format|
 			format.html
 			format.js {}
 		end

 	end
end

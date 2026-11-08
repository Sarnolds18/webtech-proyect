# Choosing the amenities of a property is part of editing it.
class PropertyAmenityPolicy < BasePolicy
  def create? = PropertyPolicy.new(user, record.property).update?
  def destroy? = create?
end

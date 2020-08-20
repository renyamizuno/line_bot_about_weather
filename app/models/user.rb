class User < ApplicationRecord
  def self.create_user(line_id, address, lat, lon)
    new_user = User.create(
      line_id: line_id,
      address: address,
      lat: lat,
      lon: lon
    )
  end

  def self.already_exist?(line_id)
    User.where(line_id: line_id).blank? ? false : true
  end
end

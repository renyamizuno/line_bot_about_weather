class User < ApplicationRecord
  scope :line_id_match, ->(line_id) {
    find_by(line_id: line_id)
  }

  def self.create_user(line_id, address, lat, lon)
    new_user = User.create(
      line_id: line_id,
      address: address,
      lat: lat,
      lon: lon
    )
  end

  def self.already_exist?(line_id)
    User.line_id_match(line_id).blank? ? false : true
  end

  def setting_info_time(selected_time)
    if self
      self.update(
        info_time: selected_time
      )
    else
      false
    end
  end

  def update_user_info(address, lat, lon)
    self.update(
      address: address,
      lat: lat,
      lon: lon
    )
  end

  def self.get_first_user_lineid
    User.first.line_id
  end
end

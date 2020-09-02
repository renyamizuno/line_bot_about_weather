class User < ApplicationRecord
  scope :line_id_match, ->(line_id) {
    find_by(line_id: line_id)
  }

  def self.already_exist?(line_id)
    User.line_id_match(line_id).blank? ? false : true
  end

  def setting_info_time(selected_time)
    self.update(
      info_time: selected_time
    )
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

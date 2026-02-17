require "test_helper"

class ProductTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "sends email notification to subscribers when back in stock" do
    product = products(:tshirt)

    # Set product inventory to 0 to simulate out of stock
    product.update(inventory_count: 0)

    assert_emails 2 do
      product.update(inventory_count: 10) # Simulate restocking the product
    end
  end
end

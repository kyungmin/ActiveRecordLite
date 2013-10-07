class MassObject
  def self.my_attr_accessible(*attributes)
    @attributes = attributes.map do |attribute|
      attribute.to_sym
    end

    attributes.each do |attribute|
      attr_accessor attribute
    end
  end

  def self.attributes
    @attributes
  end

  def self.parse_all(results)
    results.each do |result|
      self.new(result)
    end
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      if self.class.attributes.include?(attr_name)
        self.send("#{attr_name}=", value)
      else
        raise "mass assignment to unregistered attribute #{attr_name}"
      end
    end
  end
end

class MyClass < MassObject
  my_attr_accessible :x, :y
end

MyClass.new(:x => :x_val, :y => :y_val)
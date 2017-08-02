module BlocRecord
  class Collection < Array
    def take(num=1)
      self[0..num-1]
    end

    def where(data)
      result = []
        for key in data.keys
          result += self.class.update(self.id, { attribute => value })
        end
      result
    end

    def not(data)
      data.compact!
      if data.compact.count > 0
        ids = self.map(&:id)
        self.any? ? self.first.class.not(data.first, {ids: ids}) : false
      else
        self
      end
    end

    def update_all(updates)
      ids = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end
    def destroy_all
      ids = self.map(&:id)
      if ids.empty?
        puts "Nothing was deleted."
      elsif ids.first.is_nil?
        puts "No records were found to delete."
      else
        self.first.class.destroy(ids)
      end
    end
  end
end

module Nissh
  module Events

    def will(action, &block)
      add_callback(:before, action, &block)
    end

    def did(action, &block)
      add_callback(:after, action, &block)
    end

    def emit(type, action, *args)
      if @callbacks && @callbacks[action] && @callbacks[action][type]
        @callbacks[action][type].each do |callback|
          callback.call(*args)
        end
      end
    end

    private

    def add_callback(type, action, &block)
      @callbacks ||= {}
      @callbacks[action] ||= {}
      @callbacks[action][type] ||= []
      @callbacks[action][type] << block
    end

  end
end

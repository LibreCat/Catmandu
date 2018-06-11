module Foo
  module Bar
    class MyFix
      def fix(data)
        data["ruby"] = "ok"
        data
      end
    end
  end
end

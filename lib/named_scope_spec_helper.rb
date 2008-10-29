# http://gist.github.com/11918

module NamedScopeSpecHelper

  class HaveNamedScope  #:nodoc:

    def initialize(scope_name, options, proc_args=nil)
      @scope_name = scope_name.to_s
      @options    = options
      @proc_args  = proc_args
    end

    def matches?(klass)
      @klass = klass
      if @options.class == Proc
        @klass.send(@scope_name, *@proc_args).proxy_options.should === @options.call(*@proc_args)
      else
        @klass.send(@scope_name).proxy_options.should === @options
      end
      true
    end

    def failure_message
      "expected #{@klass} to define named scope '#{@scope_name}' with options #{@options.inspect}, but it didn't"
    end

    def negative_failure_message
      "expected #{@klass} to not define named scope '#{@scope_name}' with options #{@options.inspect}, but it did"
    end

  end

  def have_named_scope(scope_name, options, proc_args=nil)
    HaveNamedScope.new(scope_name, options, proc_args)
  end

end
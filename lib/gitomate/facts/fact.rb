
module Gitomate
module Facts

class Fact

include TidBits::Options::Configurable


attr_reader :depends, :happy, :name, :analyzed, :checked, :fixed, :analyzePassed, :checkPassed, :fixPassed


class << self

  attr_accessor :config

end


def initialize( default = {}, runTime = {}, depend )

	setupOptions( default, runTime )

	@depend     = *depend
	@mustDepend = *options( :mustDepend )

	requireDepends

	reset

end


def reset

	@analyzed      = false
	@checked       = false
	@fixed         = false

	@analyzePassed = false
	@checkPassed   = false
	@fixPassed     = false

end


def requireDepends

	@mustDepend.each do |depend|

		if @depend.none? { |dep| dep.class.name == depend }

			raise "#{self.class} must depend on at least one #{depend}."

		end

	end

end


def analyze( update = false )

	# We already did this step and not asked to update, nothing to do
	#
	@analyzed && !update  and  return 'return'


	# Dependencies fail, return failure
	#
	# we actually run check here and not analyze, because with dependencies
	# usually it doesn't make sense to analyze something if a dependency hasn't checked out.
	# eg. if a file must exist before we stat it, PathExist.analyze will pass when it doesn't exist,
	#     but PathExist.check won't. That's the whole point of having dependencies, so we don't
	#     try things on stuff that doesn't even exist.
	#
	if !checkDepends( update )

		@analyzed      = true
		@analyzePassed = false
		return           'return'

	end

end



def check( update = false )

	# We already did this step and not asked to update, nothing to do
	#
	@checked   && !update  and  return 'return'


	# We should update or analyze hasn't been done, analyze
	#
	!@analyzed ||  update  and  analyze( update )


	# Dependencies fail or analyze fails, return failure
	#
	if !checkDepends( update )  ||  !@analyzePassed

		@checked     = true
		@checkPassed = false
		return         'return'

	end

end



def fix( update = false )

	# We already did this step and not asked to update, nothing to do
	#
	@fixed   && !update  and  return 'return'


	# We should update or check hasn't been done, check
	#
	!@checked ||  update  and  check( update )


	# Dependencies fail or check fails, return failure
	#
	if !checkDepends( update )  ||  !@checkPassed

		@fixed     = true
		@fixPassed = false
		return       'return'

	end

end



def checkDepends( update = false )

	@depend.each do | dep |

		update || !dep.checked  and  dep.check( update )

		dep.checkPassed or return false

	end

	true

end



end # class  Fact
end # module Facts
end # module Gitomate
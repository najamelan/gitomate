
module Gitomate
module Facts
module Git


# Options (* means mandatory)
#
# path*       : Path to the repository directory (workingDir with .git)
# exist : bool   (default=true)
#
class RepoExist < Facts::Fact

attr_reader :repo, :path


def initialize( path:, **opts )

	super( Fact.config.options( :Facts, :Git, :RepoExist ), opts, path: path )

	dependOn( Path, { path: path }, type: 'directory' )

	@repo = ::Gitomate::Repo.new( Fact.config, path: path )

end



def analyze( update = false )

	super == 'return'  and  return @analyzePassed

	@state[ :exist ][ :found ] = @repo.valid?

	@analyzePassed

end



def check( update = false )

	super == 'return'  and  return @checkPassed

	key = :exist

	@state[ key ][ :passed ] = found( key ) == expect( key )  and  return @checkPassed

	# Failure
	#
	@checkPassed             = false
	@state[ key ][ :passed ] = false

	expect( key )  and  warn "#{@path.inspect} is not a git repo."
	expect( key )  or   warn "#{@path.inspect} is a git repo but it shouldn't."

	@checkPassed

end



def fix()

	super == 'return'  and  return @fixPassed

	raise "Note implemented"

end

end # class  RepoExist




# Options (* means mandatory)
#
# path*       : Path to the repository directory (workingDir with .git)
# branch      : string
# clean       : bool    (whether the working dir is clean)
#
# TODO: currently we won't check anything if the exist option doesn't correspond with reality.
#       However, we don't do input validation to keep people from asking us to test properties on a
#       repo that they claim should not be exist, which might be confusing when they check the results.
#
#       In general we should have some sort of feedback mechanism to report the reason for failures to clients.
#
class Repo < Facts::Fact

attr_reader :repo



def initialize( path:, **opts )

	super( Fact.config.options( :Facts, :Git, :Repo ), opts, path: path )

	@repo = ::Gitomate::Repo.new( Fact.config, path: @path )

	dependOn( RepoExist, { path: path } )

end



def analyze( update = false )

	super == 'return'  and  return @analyzePassed


	@state[ :branch ]  and  @state[ :branch ][ :found ] = @repo.branch
	@state[ :clean  ]  and  @state[ :clean  ][ :found ] = @repo.workingDirClean?

	@analyzePassed

end



def check( update = false )

	super == 'return'  and  return @checkPassed


	@state.each do | key, info |

		@options.has_key?( key ) or next

		info[ :passed ] = true

		if found( key ) != expect( key )

			info[ :passed ] = false
			@checkPassed    = false


			case key

			when :branch

				warn "#{@path.ai} should be on branch #{expect( key )}, but is on #{@state[ key ][ :found ].ai}."

			when :clean

				expect( key ) and warn "#{@path.ai} should have a clean working directory."
				expect( key ) or  warn "#{@path.ai} should NOT have a clean working directory."

			end


		end

	end


	@checkPassed

end



def fix()

	super == 'return'  and  return @fixPassed

	raise "Note implemented"

end


end # class  Repo



end # module Git
end # module Facts
end # module Gitomate

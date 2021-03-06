module Gitomate
module Git

class Repo

include TidBits::Options::Configurable



# The string path for the repo
#
attr_reader :path

# An array of Gitomate::Remote objects for the repository.
#
attr_reader :remotes

# An array of Gitomate::Branch objects for the repository.
#
attr_reader :branches


def initialize( path, **opts )

	setupOptions( opts )

	@path     = path
	@remotes  = {}
	@branches = {}

	# Create a backend if the repo path exist and is a repo
	#
	begin

		@git     = ::Git::Base.open @path
		@rug     = Rugged::Repository.new( @path )

		@rug.remotes.each do |remote|

			@remotes[ remote.name ] = Remote.new( remote, @git )

		end

		@rug.branches.each do |branch|

			@branches[ branch.name ] = ::Gitomate::Git::Branch.new( branch, @rug, @git )

		end


	rescue Rugged::RepositoryError, Rugged::OSError

		@rug = @git = @remotes = @branches = nil

	end

end



def pathExists?() File.exist? @path end
def valid?	   () !!@rug            end


def head

	@rug.head.name.remove( /refs\/heads\// )

end



def workingDirClean?()

	pwd = Dir.pwd
	Dir.chdir @path

	clean = `git status -s`.lines.length == 0

	# Does not work
	# @rug.diff_workdir( @rug.head.name ).size == 0

	Dir.chdir pwd

	clean

end


end # class  Repo
end # module Git
end # module Gitomate

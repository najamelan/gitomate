require 'etc'
require 'open3'

module Gitomate

class TestHelper


attr_reader :host, :prfx, :sshUser, :user, :quiet


def initialize

	@host    = 'gitcontent@localhost'
	@prfx    = 'gitomate/test/'
	@sshUser = 'gitomate'
	@user    = 'gitomate'
	@quiet   = true

	@cleanRepoSrc = File.expand_path( 'data/fixtures/clean', File.dirname( __FILE__ ) )





end


def tmpDir subPath = ''


	dir = "/run/shm/#{ Process.euid }/#{@user}/#{ randomString }/#{ subPath }"

	dir.path.mkpath

end



def dropPrivs

	uid        = Process.euid
	target_uid = Etc.getpwnam( @user ).uid

	if uid != target_uid

		TidBits::Susu.su( user: @user )

	end

end



def randomString

	rand( 36**8 ).to_s( 36 )

end



# Will create a clean repository in a tmp directory.
#
# The block will be called with:
# - the path to the repository
# - the name for the repository in gitolite
# - the exit status of the last git command in creation.
#
# Everything will be cleaned up when the block returns.
#
#
#
# def cleanRepo &block

# 	block_given? or raise ArgumentError.new 'Need block'

# 	tmp       = tmpDir
# 	shortName = randomString
# 	repoName  = "gitomate/test/#{shortName}"
# 	repoPath  = "#{tmp}/#{shortName}"
# 	out       = []

# 	out += gitoCmd "create #{repoName}"

# 	out += [ { cmd: "cd #{tmp}", status: 0 } ]
# 	Dir.chdir tmp

# 	out += cmd "git clone #{@host}:#{repoName}"

# 	out += [ { cmd: "cd #{repoPath}", status: 0 } ]
# 	Dir.chdir repoPath

# 	out += cmd "touch afile"
# 	out += cmd "git add afile"
# 	out += cmd "git commit -m'touch afile'"
# 	out += cmd "git push --set-upstream origin master"

# 	yield repoPath, repoName, out

# ensure

# 	FileUtils.remove_entry_secure tmpDir

# 	out += gitoCmd "D unlock #{repoName}"
# 	out += gitoCmd "D rm     #{repoName}"
# 	out

# end



def repo( name = randomString, &block )

	block_given? or raise ArgumentError.new 'Need block'

	tmp       = tmpDir
	shortName = name || randomString
	repoName  = "gitomate/test/#{shortName}"
	repoPath  = "#{tmp}/#{shortName}"
	out    = []

	out += [ { cmd: "cp -r #{@cleanRepoSrc}/. -> #{repoPath}", status: 0 } ]
	FileUtils.cp_r "#{@cleanRepoSrc}/.", repoPath

	out += [ { cmd: "cd #{repoPath}", status: 0 } ]
	Dir.chdir repoPath

	yield repoPath, repoName, out


ensure

	Dir.chdir repoPath
	remotes = `git remote -v` =~ /#{@host}/

	if remotes

		out += gitoCmd "D unlock #{repoName}"
		out += gitoCmd "D rm     #{repoName}"

	end


	FileUtils.remove_entry_secure tmp

	out

end



def addSubmodule( path, src )

	out = []

	Dir.chdir path

	subpath = randomString
	out += cmd  "git submodule add #{src} #{subpath}"
	out += cmd  "git submodule update --init --recursive #{subpath}"
	out += cmd  "git commit -m'Add submodule #{subpath}'"

	subPath = "#{path}/#{subpath}"

	return subPath, out

end



def addRemote( path, name = 'origin', url = false )

	Dir.chdir path

	branch       = 'master'
	remoteName   = @prfx + randomString
	url        ||= "#{@host}:#{remoteName}"

	out          = []

	out += gitoCmd "create #{remoteName}"
	out += cmd     "git remote add #{name} #{url}"
	out += cmd     "git push --set-upstream #{name} #{branch}"

	return name, url, out

end



def track( path, branch, startpoint )

	out = []

	out += cmd "git branch --set-upstream #{branch} #{startpoint}"

	out

end



def pollute path

	out = []

	file = randomString

	Dir.chdir path
	out += cmd "touch #{file}"
	out += cmd "git add #{file}"

	return file, out

end



def commitOne path

	file, out = pollute path

	out += cmd "git commit -am'commit #{file}'"

	return file, out

end



def clone path

	tmp  = tmpDir
	name = randomString
	out  = []

	Dir.chdir tmp

	out += cmd "git clone #{path} #{name}"

	return "#{tmp}/#{name}", out

end



def push path, remote = 'origin', branch = 'master'

	out  = []

	Dir.chdir path

	out += cmd "git push --set-upstream #{remote} #{branch}"

	return out

end



def changeBranch( path, branch )

	out = []

	Dir.chdir path
	out += cmd "git co #{branch}"

	# TODO: this method needs fleshing out, as changing branches might also fail
	#       if there are merge conflicts with the working dir
	#
	out.last[ :status ] == 0 or out += cmd( "git co -b #{branch}" )

	out += cmd "git status"

	out

end



def gitoCmd( cmd )

	cmd "ssh #{@host} #{cmd}"

end


# Run a system command or a sequence of commands
#
# @param cmd [string|Array<string>] The command(s) to run.
#
# options: hash
#   clearing environment variables:
#     :unsetenv_others => true   : clear environment variables except specified by env
#     :unsetenv_others => false  : don't clear (default)
#   process group:
#     :pgroup => true or 0 : make a new process group
#     :pgroup => pgid      : join to specified process group
#     :pgroup => nil       : don't change the process group (default)
#   create new process group: Windows only
#     :new_pgroup => true  : the new process is the root process of a new process group
#     :new_pgroup => false : don't create a new process group (default)
#   resource limit: resourcename is core, cpu, data, etc.  See Process.setrlimit.
#     :rlimit_resourcename => limit
#     :rlimit_resourcename => [cur_limit, max_limit]
#   umask:
#     :umask => int
#   redirection:
#     key:
#       FD              : single file descriptor in child process
#       [FD, FD, ...]   : multiple file descriptor in child process
#     value:
#       FD                        : redirect to the file descriptor in parent process
#       string                    : redirect to file with open(string, "r" or "w")
#       [string]                  : redirect to file with open(string, File::RDONLY)
#       [string, open_mode]       : redirect to file with open(string, open_mode, 0644)
#       [string, open_mode, perm] : redirect to file with open(string, open_mode, perm)
#       [:child, FD]              : redirect to the redirected file descriptor
#       :close                    : close the file descriptor in child process
#     FD is one of follows
#       :in     : the file descriptor 0 which is the standard input
#       :out    : the file descriptor 1 which is the standard output
#       :err    : the file descriptor 2 which is the standard error
#       integer : the file descriptor of specified the integer
#       io      : the file descriptor specified as io.fileno
#   file descriptor inheritance: close non-redirected non-standard fds (3, 4, 5, ...) or not
#     :close_others => true  : don't inherit
#   current directory:
#     :chdir => str
#
def cmd cmds, **options

	output = []
	cmds   = *cmds

	cmds.each do |cmd|

		stdout, stderr, status = Open3.capture3( cmd, options )

		output << { cmd: cmd, options: options, stdout: stdout, stderr: stderr, status: status }

	end

	output

end


end # class TestThorfile
end # module Gitomate

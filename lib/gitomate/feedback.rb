
module Gitomate

class Feedback

include TidBits::Options::Configurable

@@instances = {}


# Note that overriding options only works once for each progname
#
def self.get( progname )

	progname.remove!( /Gitomate::/ )
	@@instances[ progname ] || @@instances[ progname ] = self.new( progname )

end



def close

	@loggers.each { |logger| logger.close }

end



def msg2str( msg )

  case msg

  when String    then msg
  when Exception then "#{ msg.message } (#{ msg.class })\n" << ( msg.backtrace || [] ).join( "\n" )
  else                msg.inspect
  end

end



Logger::Severity.constants.each do |level|

	define_method( level.downcase ) do |*args|

		args.map! { |msg| msg2str( msg ) }
		args = [ args.join( "\n" ) ]

		@loggers.each { |logger| logger.send( level.downcase, args ) }

	end

end



private
def initialize( progname, **opts )

	setupOptions( opts )


	@loggers = []

	options.outputs.each do | name, settings |

		settings[ :enabled ] || next

		case name

		when :file

			d = options.logDir.path
			d.exist? || d.mkpath
			f = d.join options.logFile

			l           = Logger.new( f.to_s, options.keep, options.maxSize )
			l.level     = Logger::Severity.const_get( settings[ :logLevel ] )
			l.formatter = YamlLogFormat.new
			l.progname  = progname
			@loggers << l


		when :STDOUT

			l           = Logger.new( STDOUT )
			l.level     = Logger::Severity.const_get( settings[ :logLevel ] )
			l.formatter = CliLogFormat.new
			l.progname  = progname
			@loggers << l


		when :STDERR

			l           = Logger.new( STDERR )
			l.level     = Logger::Severity.const_get( settings[ :logLevel ] )
			l.formatter = CliLogFormat.new
			l.progname  = progname
			@loggers << l

		end

	end

end



end # class  Feedback
end # module Gitomate

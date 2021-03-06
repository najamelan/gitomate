require 'test/unit/testsuite'
require 'test/unit/ui/console/testrunner'

require_relative '../lib/gitomate'
require_relative '../ext/quietbacktrace/lib/quietbacktrace'


# Turn off test unit's auto runner for those using the gem
#
defined?( Test::Unit::AutoRunner ) and Test::Unit::AutoRunner.need_auto_run = false


Dir[ File.join( File.dirname( __FILE__ ), '**/*.rb' ) ].each do | file |

	require_relative file

end



module Gitomate
class  TestSuite


def self.suite

	suite =  Test::Unit::TestSuite.new( "Gitomate Unit Tests" )

	# suite << TestThorfile.suite
	suite << TestTestHelper    .suite
	suite << TestGitolite      .suite

	suite << Git::TestBranch   .suite

	suite << TestFact          .suite
	suite << TestFactPathExist .suite
	suite << TestFactPath      .suite
	suite << TestFactRepo      .suite

end



def self.run( thorObject )

	Test::Unit::UI::Console::TestRunner.run( self )

	ap 'Facts created: ' + Facts::Fact.count.to_s

end


end # TestSuite
end # Gitomate

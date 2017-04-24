require 'parser/current'

Parser::Builders::Default.emit_lambda = true
Parser::Builders::Default.emit_procarg0 = true

require "rbar/version"
require "rbar/cli"
require "rbar/inline"
require "rbar/rename"

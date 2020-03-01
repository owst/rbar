require 'parser/current'

Parser::Builders::Default.emit_lambda = true
Parser::Builders::Default.emit_procarg0 = true
Parser::Builders::Default.emit_encoding = true
Parser::Builders::Default.emit_index = true

require "rbar/version"
require "rbar/cli"
require "rbar/inline"
require "rbar/rename"

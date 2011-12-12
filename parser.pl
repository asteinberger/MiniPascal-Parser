#!/usr/bin/perl

open(INF, "<", $ARGV[0]) or die "couldn't open sourcecode\n";
{
  local $/;
  $in_buffer = <INF>;
}

chomp($in_buffer);
$in_buffer .= "\$";  # adds a $ to the end of the input to signify the end

# now, $in_buffer contains the whole input file with a $ as the last character

&lex(); # call lex to get the program started (first token should be read)
&program();  # call the subroutine associated with the start symbol

#============================================================================

# <program> ::= program <progname> <compound stmt>
sub program {
	if ($nextToken eq "program") {
		&lex();
		if ($nextToken eq "VARIABLE_OR_PROGNAME") {
			&lex();
		} else {
			&error("program name");
		} # end if
		&compoundstmt();
		if ($nextToken !~ m/^(\s*|\n*|\$)$/) {
			&error("end of file");
		} # end if
	} else {
		&error("program");
	} # end if
} # end sub

# <compound stmt> ::= begin <stmt> {; <stmt>} end
sub compoundstmt {
	if ($nextToken eq "begin") {
		&lex();
		&stmt();
		while ($nextToken eq ";") {
			&lex();
			&stmt();
		} # end while
		if ($nextToken eq "end") {
			&lex();
		} else {
			&error("end");
		} # end if
	} else {
		&error("begin");
	} # end if
} # end sub

# <stmt> ::= <simple stmt> | <structured stmt>
sub stmt {
	if ($nextToken eq "read" || $nextToken eq "write" || $nextToken eq "VARIABLE_OR_PROGNAME" || $nextToken eq "VARIABLE") {
		&simplestmt();
	} elsif ($nextToken eq "begin" || $nextToken eq "if" || $nextToken eq "while") {
		&structuredstmt();
	} else {
		&error("<simple stmt> or <structured stmt>");
	} # end if
} # end sub

# <simple stmt> ::= <assignment stmt> | <read stmt> | <write stmt>
sub simplestmt {
	if ($nextToken eq "read") {
		&readstmt();
	} elsif ($nextToken eq "write") {
		&writestmt();
	} elsif ($nextToken eq "VARIABLE_OR_PROGNAME" || $nextToken eq "VARIABLE") {
		&assignmentstmt();
	} else {
		&error("<assignment stmt>, read or write");
	} # end if
} # end sub

# <assignment stmt> ::= <variable> := <expression>
sub assignmentstmt {
	if ($nextToken eq "VARIABLE_OR_PROGNAME" || $nextToken eq "VARIABLE") {
		&lex();
	} else {
		&error("VARIABLE");
	} # end if
	if ($nextToken eq ":=") {
		&lex();
		&expression();
	} else {
		&error(":=");
	} # end if
} # end sub

# <read stmt> ::= read ( <variable> { , <variable> } )
sub readstmt {
	if ($nextToken eq "read") {
		&lex();
		if ($nextToken eq "(") {
			&lex();
			if ($nextToken eq "VARIABLE_OR_PROGNAME" || $nextToken eq "VARIABLE") {
				&lex();
			} else {
				&error("VARIABLE");
			} # end if
			while ($nextToken eq ",") {
				&lex();
				if ($nextToken eq "VARIABLE_OR_PROGNAME" || $nextToken eq "VARIABLE") {
					&lex();
				} else {
					&error("VARIABLE");
				} # end if
			} # end while
			if ($nextToken eq ")") {
				&lex();
			} else {
				&error(")");
			} # end if
		} else {
			&error("(");
		} # end if
	} else {
		&error("read");
	} # end if
} # end sub

# <write stmt> ::= write ( <expression> { , <expression> } )
sub writestmt {
	if ($nextToken eq "write") {
		&lex();
		if ($nextToken eq "(") {
			&lex();
			&expression();
			while ($nextToken eq ",") {
				&lex();
				&expression();
			} # end while
			if ($nextToken eq ")") {
				&lex();
			} else {
				&error(")");
			} # end if
		} else {
			&error("(");
		} # end if
	} else {
		&error("write");
	} # end if
} # end sub

# <structured stmt> ::= <compound stmt> | <if stmt> | <while stmt>
sub structuredstmt {
	if ($nextToken eq "begin") {
		&compoundstmt();
	} elsif ($nextToken eq "if") {
		&ifstmt();
	} elsif ($nextToken eq "while") {
		&whilestmt();
	} else {
		&error("begin, if or while");
	} # end if
} # end sub

# <if stmt> ::= if <expression> then <stmt> | if <expression> then <stmt> else <stmt>
sub ifstmt {
	if ($nextToken eq "if") {
		&lex();
		&expression();
		if ($nextToken eq "then") {
			&lex();
			&stmt();
			if ($nextToken eq "else") {
				&lex();
				&stmt();
			} # end if
		} else {
			&error("then");
		} # end if
	} else {
		&error("if");
	} # end if
} # end sub

# <while stmt> ::= while <expression> do <stmt>
sub whilestmt {
	if ($nextToken eq "while") {
		&lex();
		&expression();
		if ($nextToken eq "do") {
			&lex();
			&stmt();
		} else {
			&error("do");
		} # end if
	} else {
		&error("while");
	} # end if
} # end sub

# <expression> ::= <simple expr> | <simple expr> <relational_operator> <simple expr>
sub expression {
	if ($nextToken =~ m/^(\-|\+)$/ || $nextToken eq "VARIABLE_OR_PROGNAME" || $nextToken eq "VARIABLE" || $nextToken eq "CONSTANT" || $nextToken eq "(") {
		&simpleexpr();
	} else {
		&error("<simple expr>");
	} # end if
	if ($nextToken =~ m/^(=|\<\>|\<|\<=|\>=|\>)$/) {
		&relational_operator();
		&simpleexpr();
	} # end if
} # end sub

# <simple expr> ::= [ <sign> ] <term> { <adding_operator> <term> }
sub simpleexpr {
	if ($nextToken =~ m/^(\-|\+)$/) {
		&sign();
	} # end if
	if ($nextToken eq "VARIABLE_OR_PROGNAME" || $nextToken eq "VARIABLE" || $nextToken eq "CONSTANT" || $nextToken eq "(") {
		&term();
	} else {
		&error("<term>");
	} # end if
	while ($nextToken =~ m/^(\-|\+)$/) {
		&adding_operator();
		&term();
	} # end if
} # end sub

# <term> ::= <factor> { <multiplying_operator> <factor> }
sub term {
	if ($nextToken eq "VARIABLE_OR_PROGNAME" || $nextToken eq "VARIABLE" || $nextToken eq "CONSTANT" || $nextToken eq "(") {
		&factor();
	} else {
		&error("<factor>");
	} # end if
	while ($nextToken =~ m/^(\*|\/)$/) {
		&multiplying_operator();
		&factor();
	} # end while
} # end sub

# <factor> ::= <variable> | <constant> | ( <expression> )
sub factor {
	if ($nextToken eq "VARIABLE_OR_PROGNAME" || $nextToken eq "VARIABLE" || $nextToken eq "CONSTANT") {
		&lex();
	} elsif ($nextToken eq "(") {
		&lex();
		&expression();
		if ($nextToken eq ")") {
			&lex();
		} else {
			&error(")");
		} # end if
	} else {
		&error("<variable>, <constant> or ( <expression> )");
	} # end if
} # end sub

# <sign> ::= + | -
sub sign {
	if ($nextToken =~ m/^(\+|\-)$/) {
		&lex();
	} else {
		&error("+ or -");
	} # end if
} # end sub

# <adding_operator> ::= + | -
sub adding_operator {
	if ($nextToken =~ m/^(\+|\-)$/) {
		&lex();
	} else {
		&error("+ or -");
	} # end if
} # end sub

# <multiplying_operator> ::= * | /
sub multiplying_operator {
	if ($nextToken =~ m/^(\*|\/)$/) {
		&lex();
	} else {
		&error("* or \/");
	} # end if
} # end sub

# <relational_operator> ::= = | <> | < | <= | >= | >
sub relational_operator {
	if ($nextToken =~ m/^(=|\<\>|\<|\<=|\>=|\>)$/) {
		&lex();
	} else {
		&error("=, <>, <, <=, >= or >");
	} # end if
} # end sub

# this is what happens when shit hits the fan!
sub error {
	print "Error: saw $nextToken but expected $_[0]\n";
} # end sub

# lexical analyzer
sub lex {
#	print "==========\n";
#	print "$in_buffer\n";
	$in_buffer =~ s/(program|begin|;|end|:=|read|\(|,|\)|write|if|then|else|while|do|\+|\-|\*|\/|=|\<\>|\<|\<=|\>=|\>|\$|[A-Z][A-Za-z0-9]*|[A-Za-z][A-Za-z0-9]*|(\+|\-)?[0-9]+)//s;
	$nextToken = $1;
#	print "$in_buffer\n";
#	print "$nextToken\n";
	unless ($nextToken =~ m/^\s*(program|begin|;|end|:=|read|\(|,|\)|write|if|then|else|while|do|\+|\-|\*|\/|=|\<\>|\<|\<=|\>=|\>|\$)\s*$/) {
		if ($nextToken =~ m/^[A-Z][A-Za-z0-9]*$/) {
			$nextToken = "VARIABLE_OR_PROGNAME";
		} elsif ($nextToken =~ m/^[A-Za-z][A-Za-z0-9]*$/) {
			$nextToken = "VARIABLE";
		} elsif ($nextToken =~ m/^(\+|\-)?[0-9]+$/) {
			$nextToken = "CONSTANT";
		} else {
			&error("VARIABLE_OR_PROGNAME, VARIABLE or CONSTANT");
		} # end if
	} # end unless
} # end sub

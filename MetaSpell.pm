#!/usr/bin/perl

package Umka::MetaSpell;

# Confgure package behaviour
use 5.8.1;
use strict;
use warnings;

# Define a list of required modules
use IPC::Open2;
use Carp;

# Declare a list of global variables
our $pid;
our $version;

sub new( $;@ )
{
    # Initialise local class
    my $class = shift( @_ );
    my $this = {};
    bless( $this, $class );

    # Validate and define aspell command
    my ( $command, @arguments ) = @_;
    croak( "Could not execute $command requested" ) unless ( -x $command );
    my $init_command = join( ' ', $command, @arguments );

    # Open a bidirectional pine to TO_ASPELL process
    $pid = open2( \*FROM_ASPELL, \*TO_ASPELL, "$init_command pipe" );
    $version = <FROM_ASPELL>;

    return $this;
}

sub end()
{
    my $this = shift( @_ );

    # Close all filehandles and wait for TO_ASPELL process to finish
    close( TO_ASPELL );
    close( FROM_ASPELL );
    my $output = waitpid( $pid, 0 );

    return $output;
}

sub setMode( $ )
{
    my ( $this, $mode ) = @_;

    # Define a list of mode synonyms
    my %synonyms = (
            'default'   => '-',
            'verbose'   => '%',
            'quiet'     => '!' );

    # Returrn to the default mode
    if ( $synonyms{ $mode }) {
        print( TO_ASPELL $synonyms{ $mode }."\n" );
    }

    # Initialise requested mode
    else {
        print( TO_ASPELL "+$mode\n" );
    }

    return 1;
}

sub setOption( $$ )
{
    my ( $this, $option, $value ) = @_;

    # Change a specific configuration option
    print( TO_ASPELL '$$'."cs $option, $value\n" );

    return 1;
}

sub getOption( $ )
{
    my ( $this, $option ) = @_;

    # Request and return the value of an option
    print( TO_ASPELL '$$'."cr $option\n" );
    chomp( my $output = <FROM_ASPELL> );

    return $output;
}

sub addWord( $;$ )
{
    my ( $this, $word, $mode ) = @_;

    # Define a list of mode synonyms
    my %synonyms = (
            'session'   => '@',
            'personal'  => '&',
            'asis'      => '*' );

    # Add a word using a mode synonym
    if ( $synonyms{ $mode }) {
        print( TO_ASPELL $synonyms{ $mode }.$word."\n" );
    }

    # Fall back on the default mode (session)
    else {
        print( TO_ASPELL '@'.$word."\n" );
    }

    return 1;
}

sub getWords( ;$ )
{
    my ( $this, $mode ) = @_;
    my ( $count, $list, @output );

    # Define a list of mode synonyms
    my %synonyms = (
            'session'   => '$$ps',
            'personal'  => '$$pp' );

    # Catch a special case when requesting all stored words
    if ( $mode eq "all" ) {
        # Get all words stored in the personal dictionary
        print( TO_ASPELL '$$pp'."\n" );
        ( $count, $list ) = split( /: /, <FROM_ASPELL>, 2 );
        @output = split( /, /, $list );

        # Get all words stored in the session dictionary
        print( TO_ASPELL '$$ps'."\n" );
        ( $count, $list ) = split( /: /, <FROM_ASPELL>, 2 );
        push( @output, split( /, /, $list ));
    }

    # Report requested list of words
    else {
        my $command = ( $synonyms{ $mode } ? $synonyms{ $mode } : '$$ps' );
        print( TO_ASPELL "$command\n" );
        ( $count, $list ) = split( /: /, <FROM_ASPELL>, 2 );
        @output = split( /, /, $list );
    }

    return @output;
}

sub saveWords()
{
    my $this = shift( @_ );

    # Save current personal dictionary
    print( TO_ASPELL "#\n" );

    return 1;
}

sub checkLine( $ )
{
    my ( $this, $line ) = @_;
    my @output;

    # Make sure that no line breaks are present
    $line =~ s/\n/ /sg;

    # Spell check required line
    print( TO_ASPELL '^'.$line."\n" );
    chomp( $line = <FROM_ASPELL> );

    # Process all output from the pipe until a blank line
    while ( $line =~ m/\s+/ ) {
        my ( $mode, $result ) = split( / /, $line, 2 );
        my ( $column, $word, $list, $count );

        # Capture misspelled words that have no suggestions
        if ( $mode eq '#' ) {
            ( $word, $column ) = split( / /, $result );
        }

        # Capture misspelled words that have suggestions
        elsif ( $mode eq '&' ) {
            ( $word, $count, $column, $list ) = split( / /, $result, 4 );
            chop( $column );
        }

        push( @output, {
                'offset'        => $column,
                'word'          => $word,
                'suggestions'   => $list });

        chomp( $line = <FROM_ASPELL> );
    }

    return @output;
}

sub checkText( $ )
{
    my ( $this, $text ) = @_;
    my $counter = 1;
    my @output;

    # Separate text into single lines
    my @text = split( "\n", $text );

    # Proces separately each line
    foreach my $line ( @text ) {
        my @errors = $this -> checkLine( $line );

        # Add line identifier to the error message
        foreach my $error ( @errors ) {
            $error -> { 'line' } = $counter;
            unshift( @output, $error );
        }

        # Advance counter
        $counter++;
    }

    return @output;
}

1;

__END__

=pod

=head1 NAME

Umka::MetaSpell - object-orientated interface to aspell's pipe mode

=head1 SYNOPSIS

The following is an example of the way this module can be used from within a
custom script. This example will start a new aspell process using a specific
language with predefined encoding, switch to a quiet, html mode and spell
check a custom block of text:

    my $Spell = new Umka::MetaSpell( '/usr/local/bin/aspell' );

    $Spell -> setOption( 'lang', 'en' );
    $Spell -> setOption( 'encoding', 'utf-8' )

    $Spell -> setMode( 'quiet' );
    $Spell -> setMode( 'html' );

    my @error = $Spell -> checkText( $my_html );

=head1 DESCRIPTION

When searching CPAN for a possible solution to my spell checking problem, I
have found that most released modules only deal with plain text and only in
ascii or latin-1 encoding. Out of the box, aspell not only supports a vast
number of languages in various encoding, but it also capable of spell checking
a number of different file formats (txt, html, man ...). Until the release of
this module, this functionality was lost to Perl community.

This module is designed to provide an object-orientated interface to aspell's
pipe mode. It is largely compatible with "ispell -a" mode (see
L<Incompatibilities> section for more information) and allows a user to start
and control an aspell process while sending multiple text blocks for it to
process. Output of the program is then collected and processed. This way,
multiple blocks of text can be spell checked within a single aspell process,
saving precious system resources.

=head2 Requirements

The following is a list of modules required by Umka::MetaSpell. Please note that
version numbers indicate the version of a module this package was built with.
With minor tweaking you should be able to get Umka::MetaSpell to run with older
versions of the same modules.

    Aspell      0.60.4  interactive spell checker (binary required)
    IPC::Open2  1.02    Open a process for both reading and writing
    Carp        1.03    Throw exceptions outside current package

=head2 Installation

Currently this module is not distributed as part of the CPAN archive,
therefore installing it is not as simple as doing C<install Umka::MetaSpell> from
the CPAN shell. However, it is not much harder then that either.

First of all make sure that you have successfully installed all of the modules
listed in the required section. Once that is done, complete installation by
copying the module to a location where perl can find it.

A list of directories searched by perl for a file you are attempting to C<use>
or C<require> can be found by running C<perl -V> or set by using C<use lib
'/path/to/module'> pragma within a script.

=head2 Incompatibilities

Please note that this module is designed to be compatible with both C<aspell>
and C<ispell> command line utilities. However, since C<aspell> extends
C<ispell>'s functionality by providing a proprietary interface to some of it's
functions, some of the methods defined in this module will only work with
C<aspell>.

The following is a list of C<aspell> only methods defined by this module:

    setOption       defines a new value of aspell only options
    getOption       retreives curent value of aspell only options
    getWords        returns a list of all words in dictionaries

=head1 METHODS

=head2 Publicly Available

The following is a list of publicly available methods, their arguments and
return values. Any changes to the syntax of this methods would result in a
change to the minor version of the library.

=head3 new( command, arguments )

Creates and returns a new Umka::Browser object.

=over

=item command (required; string)

Path (absolute or relative) to the location of the aspell binary.

    new Umka::MetaSpell( '/usr/local/bin/aspell' );

=item arguments (optional; string or array)

A list of arguments to be passed to the aspell process upon its invocation.
Please note that each new argument should be passed as a separate element of
the array. If only one argument is passed then it is possible to pass it as a
string.

    new Umka::MetaSpell( 'aspell', '--personal=/path/to/dict' );
    new Umka::MetaSpell( 'aspell', '--lang=en', '--encoding=utf-8' );

=back

=head3 end( )

This method is used to terminate all file handles to the current aspell
process after which it will wait for current connection to be closed before
returning the pid of the deceased process, or -1 if there is no such child
process. For more information on the returned values please see C<waitpid>
manual page.

    $Spell -> end();

=head3 setMode( mode )

This method is used to modify aspell's behaviour by allowing a user to switch
current spell checking B<mode>. Thus, all further input will be checked
according to the syntax of the new B<mode>.

=over

=item mode (required; string)

A valid B<mode> will cause Aspell to parse future input according the syntax
of that formatter. For more information about different modes see aspell
manual page. Examples of different modes are: html, email, url, tex.

In addition to all modes supported by aspell this method supports the
following custom modes: I<quiet> - enter terse mode, I<verbose> - exit terse
mode, I<default> - enter the default mode.

    $Spell -> setMode( 'html' );

=back

=head3 setOption( option, value )

This method allows changing of the Aspell specific extensions. This method is
provided in addition to the C<setMode()> command, which is designed for Ispell
compatibility. This method always returns 1.

=over

=item option (required; string)

Defines a name of the configuration option to be modified by the supplied
value. See aspell manual page for more information.

    $Setup -> setOption( 'repl', '/path/to/replacement/list' );

=item value (required; string)

Defines a new value for the option supplied by B<option>.

    $Setup -> setOption( 'personal', '/path/to/personal/dict' );

=back

=head3 getOption( option )

This method allows retrieving of the Aspell specific extensions. This method
is provided in addition to the C<setMode()> command, which is designed for
Ispell compatibility. This method always returns 1.

=over

=item option (required; string)

Defines a name of the configuration option to be retrieved by module. See
aspell manual page for more information.

    $Spell -> getOption( 'dict-dir' );

=back

=head3 addWord( word; mode )

This method will allow a user to add current B<word> to the dictionary using a
specific B<mode>. If no mode is specified then words are added to the session
dictionary. This method always returns 1.

=over

=item word (required; string)

A word to be added to dictionary.

    $Spell -> addWord( 'Umka' );

=item mode (optional; string)

The following modes are supported: I<session> - accept the word for current
session but leave it out of the dictionary, I<personal> - insert the
all-lowercase version of the word in the personal dictionary, I<asis> - add a
word to the personal dictionary.

    $Spell -> addWord( 'Umka', 'session' );

=back

=head3 getWords( mode )

This method allows retrieval of the complete list of words from either a
current session dictionary or a personal word list (depending on the supplied
B<mode>). Method returns an array of words stored in a dictionary.

=over

=item mode (required; string)

The following modes are supported: I<session> - list words from current
session dictionary, I<personal> - list words from personal dictionary, I<all>
- list words from both personal and session dictionaries. If a word appears in
both dictionaries then it will be listed twice.

    $Spell -> getWords( 'all' );

=back

=head3 saveWords( )

This method takes no arguments and is used to allow user to save their
personal word list / dictionary file. This method always returns 1.

    $Spell -> saveWords();

=head3 checkLine( line )

This method allows a user to spell check a single line of text. Upon a
successful check an array of anonymous hashes will be returned. Each hash will
correspond to a spelling error, listing the following information: I<offset> -
a column in which misspelled word has been found, I<word> - a word that has
been misspelled, I<suggestions> - a comma separated list of possible
suggestions.

=over

=item line (required; string)

A line of text to be spell checked. Before initialising spell checker, all
newline characters (\n) will be removed from the supplied line.

    $Spell -> checkLine( "Goodbye cruel worlld \n"
            ."I'm leving you today \n"
            ."Godbye, goodbye, goodbye" );

=back

=head3 checkText( text )

This method allows a user to spell check a block of text. Upon a successful
check an array of anonymous hashes will be returned. Each hash will correspond
to a spelling error, listing the following information: I<line> - a line
number in which misspelling has occured, I<offset> - a column in which
misspelled word has been found, I<word> - a word that has been misspelled,
I<suggestions> - a comma separated list of possible suggestions.

=over

=item text (required; string)

A block of text to be spell checked. All newline characters (\n) in the
supplied text will be preserved during the check.

    $Spell -> checkText( "Goodbye cruel worlld \n"
            ."I'm leving you today \n"
            ."Goobye, goodbye, goodbye." );

=back

=head2 Internal Access

This module has no internal methods.

=head1 SEE ALSO

For further information about all posible options used by Aspell, their
default values and how they can be set please see aspell manual page or
project's webpage. (http://aspell.sourceforge.net/man-html/)

Text::Aspell, Text::SpellCheck, Text::SpellChecker

=cut

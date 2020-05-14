MetaSpell
=========

**Status:** ARCHIVED - Fully functional, but missing tests  
**Version:** 2.0.79  

*   [NAME](#NAME)
*   [SYNOPSIS](#SYNOPSIS)
*   [DESCRIPTION](#DESCRIPTION)
    *   [Requirements](#Requirements)
    *   [Installation](#Installation)
    *   [Incompatibilities](#Incompatibilities)
*   [METHODS](#METHODS)
    *   [Publicly Available](#Publicly-Available)
        *   [new( command, arguments )](#new-command-arguments)
        *   [end( )](#end)
        *   [setMode( mode )](#setMode-mode)
        *   [setOption( option, value )](#setOption-option-value)
        *   [getOption( option )](#getOption-option)
        *   [addWord( word; mode )](#addWord-word-mode)
        *   [getWords( mode )](#getWords-mode)
        *   [saveWords( )](#saveWords)
        *   [checkLine( line )](#checkLine-line)
        *   [checkText( text )](#checkText-text)
    *   [Internal Access](#Internal-Access)
*   [SEE ALSO](#SEE-ALSO)
*   [DONATIONS](#DONATIONS)

## NAME

Umka::MetaSpell - object-orientated interface to aspell's pipe mode

## SYNOPSIS

The following is an example of the way this module can be used from within a custom script. This example will start a new aspell process using a specific language with predefined encoding, switch to a quiet, html mode and spell check a custom block of text:

        my $Spell = new Umka::MetaSpell( '/usr/local/bin/aspell' );

        $Spell -> setOption( 'lang', 'en' );
        $Spell -> setOption( 'encoding', 'utf-8' )

        $Spell -> setMode( 'quiet' );
        $Spell -> setMode( 'html' );

        my @error = $Spell -> checkText( $my_html );

## DESCRIPTION

When searching CPAN for a possible solution to my spell checking problem, I have found that most released modules only deal with plain text and only in ascii or latin-1 encoding. Out of the box, aspell not only supports a vast number of languages in various encoding, but it also capable of spell checking a number of different file formats (txt, html, man ...). Until the release of this module, this functionality was lost to Perl community.

This module is designed to provide an object-orientated interface to aspell's pipe mode. It is largely compatible with "ispell -a" mode (see [Incompatibilities](#Incompatibilities) section for more information) and allows a user to start and control an aspell process while sending multiple text blocks for it to process. Output of the program is then collected and processed. This way, multiple blocks of text can be spell checked within a single aspell process, saving precious system resources.

### Requirements

The following is a list of modules required by Umka::MetaSpell. Please note that version numbers indicate the version of a module this package was built with. With minor tweaking you should be able to get Umka::MetaSpell to run with older versions of the same modules.

        Aspell      0.60.4  interactive spell checker (binary required)
        IPC::Open2  1.02    Open a process for both reading and writing
        Carp        1.03    Throw exceptions outside current package

### Installation

Currently this module is not distributed as part of the CPAN archive, therefore installing it is not as simple as doing `install Umka::MetaSpell` from the CPAN shell. However, it is not much harder then that either.

First of all make sure that you have successfully installed all of the modules listed in the required section. Once that is done, complete installation by copying the module to a location where perl can find it.

A list of directories searched by perl for a file you are attempting to `use` or `require` can be found by running `perl -V` or set by using `use lib '/path/to/module'` pragma within a script.

### Incompatibilities

Please note that this module is designed to be compatible with both `aspell` and `ispell` command line utilities. However, since `aspell` extends `ispell`'s functionality by providing a proprietary interface to some of it's functions, some of the methods defined in this module will only work with `aspell`.

The following is a list of `aspell` only methods defined by this module:

        setOption       defines a new value of aspell only options
        getOption       retreives curent value of aspell only options
        getWords        returns a list of all words in dictionaries

## METHODS

### Publicly Available

The following is a list of publicly available methods, their arguments and return values. Any changes to the syntax of this methods would result in a change to the minor version of the library.

#### new( command, arguments )

Creates and returns a new Umka::Browser object.

<dl>

<dt id="command-required-string">command (required; string)</dt>

<dd>

Path (absolute or relative) to the location of the aspell binary.

        new Umka::MetaSpell( '/usr/local/bin/aspell' );

</dd>

<dt id="arguments-optional-string-or-array">arguments (optional; string or array)</dt>

<dd>

A list of arguments to be passed to the aspell process upon its invocation. Please note that each new argument should be passed as a separate element of the array. If only one argument is passed then it is possible to pass it as a string.

        new Umka::MetaSpell( 'aspell', '--personal=/path/to/dict' );
        new Umka::MetaSpell( 'aspell', '--lang=en', '--encoding=utf-8' );

</dd>

</dl>

#### end( )

This method is used to terminate all file handles to the current aspell process after which it will wait for current connection to be closed before returning the pid of the deceased process, or -1 if there is no such child process. For more information on the returned values please see `waitpid` manual page.

        $Spell -> end();

#### setMode( mode )

This method is used to modify aspell's behaviour by allowing a user to switch current spell checking **mode**. Thus, all further input will be checked according to the syntax of the new **mode**.

<dl>

<dt id="mode-required-string">mode (required; string)</dt>

<dd>

A valid **mode** will cause Aspell to parse future input according the syntax of that formatter. For more information about different modes see aspell manual page. Examples of different modes are: html, email, url, tex.

In addition to all modes supported by aspell this method supports the following custom modes: _quiet_ - enter terse mode, _verbose_ - exit terse mode, _default_ - enter the default mode.

        $Spell -> setMode( 'html' );

</dd>

</dl>

#### setOption( option, value )

This method allows changing of the Aspell specific extensions. This method is provided in addition to the `setMode()` command, which is designed for Ispell compatibility. This method always returns 1.

<dl>

<dt id="option-required-string">option (required; string)</dt>

<dd>

Defines a name of the configuration option to be modified by the supplied value. See aspell manual page for more information.

        $Setup -> setOption( 'repl', '/path/to/replacement/list' );

</dd>

<dt id="value-required-string">value (required; string)</dt>

<dd>

Defines a new value for the option supplied by **option**.

        $Setup -> setOption( 'personal', '/path/to/personal/dict' );

</dd>

</dl>

#### getOption( option )

This method allows retrieving of the Aspell specific extensions. This method is provided in addition to the `setMode()` command, which is designed for Ispell compatibility. This method always returns 1.

<dl>

<dt id="option-required-string1">option (required; string)</dt>

<dd>

Defines a name of the configuration option to be retrieved by module. See aspell manual page for more information.

        $Spell -> getOption( 'dict-dir' );

</dd>

</dl>

#### addWord( word; mode )

This method will allow a user to add current **word** to the dictionary using a specific **mode**. If no mode is specified then words are added to the session dictionary. This method always returns 1.

<dl>

<dt id="word-required-string">word (required; string)</dt>

<dd>

A word to be added to dictionary.

        $Spell -> addWord( 'Umka' );

</dd>

<dt id="mode-optional-string">mode (optional; string)</dt>

<dd>

The following modes are supported: _session_ - accept the word for current session but leave it out of the dictionary, _personal_ - insert the all-lowercase version of the word in the personal dictionary, _asis_ - add a word to the personal dictionary.

        $Spell -> addWord( 'Umka', 'session' );

</dd>

</dl>

#### getWords( mode )

This method allows retrieval of the complete list of words from either a current session dictionary or a personal word list (depending on the supplied **mode**). Method returns an array of words stored in a dictionary.

<dl>

<dt id="mode-required-string1">mode (required; string)</dt>

<dd>

The following modes are supported: _session_ - list words from current session dictionary, _personal_ - list words from personal dictionary, _all_ - list words from both personal and session dictionaries. If a word appears in both dictionaries then it will be listed twice.

        $Spell -> getWords( 'all' );

</dd>

</dl>

#### saveWords( )

This method takes no arguments and is used to allow user to save their personal word list / dictionary file. This method always returns 1.

        $Spell -> saveWords();

#### checkLine( line )

This method allows a user to spell check a single line of text. Upon a successful check an array of anonymous hashes will be returned. Each hash will correspond to a spelling error, listing the following information: _offset_ - a column in which misspelled word has been found, _word_ - a word that has been misspelled, _suggestions_ - a comma separated list of possible suggestions.

<dl>

<dt id="line-required-string">line (required; string)</dt>

<dd>

A line of text to be spell checked. Before initialising spell checker, all newline characters (\n) will be removed from the supplied line.

        $Spell -> checkLine( "Goodbye cruel worlld \n"
                ."I'm leving you today \n"
                ."Godbye, goodbye, goodbye" );

</dd>

</dl>

#### checkText( text )

This method allows a user to spell check a block of text. Upon a successful check an array of anonymous hashes will be returned. Each hash will correspond to a spelling error, listing the following information: _line_ - a line number in which misspelling has occured, _offset_ - a column in which misspelled word has been found, _word_ - a word that has been misspelled, _suggestions_ - a comma separated list of possible suggestions.

<dl>

<dt id="text-required-string">text (required; string)</dt>

<dd>

A block of text to be spell checked. All newline characters (\n) in the supplied text will be preserved during the check.

        $Spell -> checkText( "Goodbye cruel worlld \n"
                ."I'm leving you today \n"
                ."Goobye, goodbye, goodbye." );

</dd>

</dl>

### Internal Access

This module has no internal methods.

## SEE ALSO

For further information about all posible options used by Aspell, their default values and how they can be set please see aspell manual page or project's webpage. (http://aspell.sourceforge.net/man-html/)

Text::Aspell, Text::SpellCheck, Text::SpellChecker

## DONATIONS

This module is 100% free and is distributed under the terms of the MIT license. You're welcome to use it for private or commercial projects and to generally do whatever you want with it.

If you found this module useful, would like to support its further development, or you are just feeling generous, then your contribution will be greatly appreciated!

<p align="center">
  <a href="https://paypal.me/UmkaDK"><img src="https://img.shields.io/badge/paypal-me-blue.svg?colorB=0070ba&logo=paypal" alt="PayPal.Me"></a>
  &nbsp;
  <a href="https://commerce.coinbase.com/checkout/65cb49bf-3b08-41df-97fd-df8a69705b3d"><img src="https://img.shields.io/badge/coinbase-donate-gold.svg?colorB=ff8e00&logo=bitcoin" alt="Donate via Coinbase"></a>
</p>

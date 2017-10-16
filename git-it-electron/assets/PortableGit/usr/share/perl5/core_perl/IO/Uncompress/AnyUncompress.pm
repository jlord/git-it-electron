package IO::Uncompress::AnyUncompress ;

use strict;
use warnings;
use bytes;

use IO::Compress::Base::Common 2.068 ();

use IO::Uncompress::Base 2.068 ;


require Exporter ;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS, $AnyUncompressError);

$VERSION = '2.068';
$AnyUncompressError = '';

@ISA = qw( Exporter IO::Uncompress::Base );
@EXPORT_OK = qw( $AnyUncompressError anyuncompress ) ;
%EXPORT_TAGS = %IO::Uncompress::Base::DEFLATE_CONSTANTS ;
push @{ $EXPORT_TAGS{all} }, @EXPORT_OK ;
Exporter::export_ok_tags('all');

# TODO - allow the user to pick a set of the three formats to allow
#        or just assume want to auto-detect any of the three formats.

BEGIN
{
   eval ' use IO::Uncompress::Adapter::Inflate 2.068 ;';
   eval ' use IO::Uncompress::Adapter::Bunzip2 2.068 ;';
   eval ' use IO::Uncompress::Adapter::LZO 2.068 ;';
   eval ' use IO::Uncompress::Adapter::Lzf 2.068 ;';
   eval ' use IO::Uncompress::Adapter::UnLzma 2.068 ;';
   eval ' use IO::Uncompress::Adapter::UnXz 2.068 ;';

   eval ' use IO::Uncompress::Bunzip2 2.068 ;';
   eval ' use IO::Uncompress::UnLzop 2.068 ;';
   eval ' use IO::Uncompress::Gunzip 2.068 ;';
   eval ' use IO::Uncompress::Inflate 2.068 ;';
   eval ' use IO::Uncompress::RawInflate 2.068 ;';
   eval ' use IO::Uncompress::Unzip 2.068 ;';
   eval ' use IO::Uncompress::UnLzf 2.068 ;';
   eval ' use IO::Uncompress::UnLzma 2.068 ;';
   eval ' use IO::Uncompress::UnXz 2.068 ;';
}

sub new
{
    my $class = shift ;
    my $obj = IO::Compress::Base::Common::createSelfTiedObject($class, \$AnyUncompressError);
    $obj->_create(undef, 0, @_);
}

sub anyuncompress
{
    my $obj = IO::Compress::Base::Common::createSelfTiedObject(undef, \$AnyUncompressError);
    return $obj->_inf(@_) ;
}

sub getExtraParams
{ 
    return ( 'rawinflate' => [IO::Compress::Base::Common::Parse_boolean,  0] ,
             'unlzma'     => [IO::Compress::Base::Common::Parse_boolean,  0] ) ;
}

sub ckParams
{
    my $self = shift ;
    my $got = shift ;

    # any always needs both crc32 and adler32
    $got->setValue('crc32' => 1);
    $got->setValue('adler32' => 1);

    return 1;
}

sub mkUncomp
{
    my $self = shift ;
    my $got = shift ;

    my $magic ;

    # try zlib first
    if (defined $IO::Uncompress::RawInflate::VERSION )
    {
        my ($obj, $errstr, $errno) = IO::Uncompress::Adapter::Inflate::mkUncompObject();

        return $self->saveErrorString(undef, $errstr, $errno)
            if ! defined $obj;

        *$self->{Uncomp} = $obj;
        
        my @possible = qw( Inflate Gunzip Unzip );
        unshift @possible, 'RawInflate' 
            if $got->getValue('rawinflate');

        $magic = $self->ckMagic( @possible );
        
        if ($magic) {
            *$self->{Info} = $self->readHeader($magic)
                or return undef ;

            return 1;
        }
     }

    if (defined $IO::Uncompress::UnLzma::VERSION && $got->getValue('unlzma'))
    {
        my ($obj, $errstr, $errno) = IO::Uncompress::Adapter::UnLzma::mkUncompObject();

        return $self->saveErrorString(undef, $errstr, $errno)
            if ! defined $obj;

        *$self->{Uncomp} = $obj;
        
        my @possible = qw( UnLzma );
        #unshift @possible, 'RawInflate' 
        #    if $got->getValue('rawinflate');

        if ( *$self->{Info} = $self->ckMagic( @possible ))
        {
            return 1;
        }
     }

     if (defined $IO::Uncompress::UnXz::VERSION and
         $magic = $self->ckMagic('UnXz')) {
        *$self->{Info} = $self->readHeader($magic)
            or return undef ;

        my ($obj, $errstr, $errno) =
            IO::Uncompress::Adapter::UnXz::mkUncompObject();

        return $self->saveErrorString(undef, $errstr, $errno)
            if ! defined $obj;

        *$self->{Uncomp} = $obj;

         return 1;
     }

     if (defined $IO::Uncompress::Bunzip2::VERSION and
         $magic = $self->ckMagic('Bunzip2')) {
        *$self->{Info} = $self->readHeader($magic)
            or return undef ;

        my ($obj, $errstr, $errno) = IO::Uncompress::Adapter::Bunzip2::mkUncompObject();

        return $self->saveErrorString(undef, $errstr, $errno)
            if ! defined $obj;

        *$self->{Uncomp} = $obj;

         return 1;
     }

     if (defined $IO::Uncompress::UnLzop::VERSION and
            $magic = $self->ckMagic('UnLzop')) {

        *$self->{Info} = $self->readHeader($magic)
            or return undef ;

        my ($obj, $errstr, $errno) = IO::Uncompress::Adapter::LZO::mkUncompObject();

        return $self->saveErrorString(undef, $errstr, $errno)
            if ! defined $obj;

        *$self->{Uncomp} = $obj;

         return 1;
     }

     if (defined $IO::Uncompress::UnLzf::VERSION and
            $magic = $self->ckMagic('UnLzf')) {

        *$self->{Info} = $self->readHeader($magic)
            or return undef ;

        my ($obj, $errstr, $errno) = IO::Uncompress::Adapter::Lzf::mkUncompObject();

        return $self->saveErrorString(undef, $errstr, $errno)
            if ! defined $obj;

        *$self->{Uncomp} = $obj;

         return 1;
     }

     return 0 ;
}



sub ckMagic
{
    my $self = shift;
    my @names = @_ ;

    my $keep = ref $self ;
    for my $class ( map { "IO::Uncompress::$_" } @names)
    {
        bless $self => $class;
        my $magic = $self->ckMagic();

        if ($magic)
        {
            #bless $self => $class;
            return $magic ;
        }

        $self->pushBack(*$self->{HeaderPending})  ;
        *$self->{HeaderPending} = ''  ;
    }    

    bless $self => $keep;
    return undef;
}

1 ;

__END__


=head1 NAME

IO::Uncompress::AnyUncompress - Uncompress gzip, zip, bzip2 or lzop file/buffer

=head1 SYNOPSIS

    use IO::Uncompress::AnyUncompress qw(anyuncompress $AnyUncompressError) ;

    my $status = anyuncompress $input => $output [,OPTS]
        or die "anyuncompress failed: $AnyUncompressError\n";

    my $z = new IO::Uncompress::AnyUncompress $input [OPTS] 
        or die "anyuncompress failed: $AnyUncompressError\n";

    $status = $z->read($buffer)
    $status = $z->read($buffer, $length)
    $status = $z->read($buffer, $length, $offset)
    $line = $z->getline()
    $char = $z->getc()
    $char = $z->ungetc()
    $char = $z->opened()

    $data = $z->trailingData()
    $status = $z->nextStream()
    $data = $z->getHeaderInfo()
    $z->tell()
    $z->seek($position, $whence)
    $z->binmode()
    $z->fileno()
    $z->eof()
    $z->close()

    $AnyUncompressError ;

    # IO::File mode

    <$z>
    read($z, $buffer);
    read($z, $buffer, $length);
    read($z, $buffer, $length, $offset);
    tell($z)
    seek($z, $position, $whence)
    binmode($z)
    fileno($z)
    eof($z)
    close($z)

=head1 DESCRIPTION

This module provides a Perl interface that allows the reading of
files/buffers that have been compressed with a variety of compression
libraries.

The formats supported are:

=over 5

=item RFC 1950

=item RFC 1951 (optionally)

=item gzip (RFC 1952)

=item zip

=item bzip2

=item lzop

=item lzf

=item lzma

=item xz

=back

The module will auto-detect which, if any, of the supported
compression formats is being used.

=head1 Functional Interface

A top-level function, C<anyuncompress>, is provided to carry out
"one-shot" uncompression between buffers and/or files. For finer
control over the uncompression process, see the L</"OO Interface">
section.

    use IO::Uncompress::AnyUncompress qw(anyuncompress $AnyUncompressError) ;

    anyuncompress $input_filename_or_reference => $output_filename_or_reference [,OPTS] 
        or die "anyuncompress failed: $AnyUncompressError\n";

The functional interface needs Perl5.005 or better.

=head2 anyuncompress $input_filename_or_reference => $output_filename_or_reference [, OPTS]

C<anyuncompress> expects at least two parameters,
C<$input_filename_or_reference> and C<$output_filename_or_reference>.

=head3 The C<$input_filename_or_reference> parameter

The parameter, C<$input_filename_or_reference>, is used to define the
source of the compressed data. 

It can take one of the following forms:

=over 5

=item A filename

If the <$input_filename_or_reference> parameter is a simple scalar, it is
assumed to be a filename. This file will be opened for reading and the
input data will be read from it.

=item A filehandle

If the C<$input_filename_or_reference> parameter is a filehandle, the input
data will be read from it.  The string '-' can be used as an alias for
standard input.

=item A scalar reference 

If C<$input_filename_or_reference> is a scalar reference, the input data
will be read from C<$$input_filename_or_reference>.

=item An array reference 

If C<$input_filename_or_reference> is an array reference, each element in
the array must be a filename.

The input data will be read from each file in turn. 

The complete array will be walked to ensure that it only
contains valid filenames before any data is uncompressed.

=item An Input FileGlob string

If C<$input_filename_or_reference> is a string that is delimited by the
characters "<" and ">" C<anyuncompress> will assume that it is an 
I<input fileglob string>. The input is the list of files that match the 
fileglob.

See L<File::GlobMapper|File::GlobMapper> for more details.

=back

If the C<$input_filename_or_reference> parameter is any other type,
C<undef> will be returned.

=head3 The C<$output_filename_or_reference> parameter

The parameter C<$output_filename_or_reference> is used to control the
destination of the uncompressed data. This parameter can take one of
these forms.

=over 5

=item A filename

If the C<$output_filename_or_reference> parameter is a simple scalar, it is
assumed to be a filename.  This file will be opened for writing and the 
uncompressed data will be written to it.

=item A filehandle

If the C<$output_filename_or_reference> parameter is a filehandle, the
uncompressed data will be written to it.  The string '-' can be used as
an alias for standard output.

=item A scalar reference 

If C<$output_filename_or_reference> is a scalar reference, the
uncompressed data will be stored in C<$$output_filename_or_reference>.

=item An Array Reference

If C<$output_filename_or_reference> is an array reference, 
the uncompressed data will be pushed onto the array.

=item An Output FileGlob

If C<$output_filename_or_reference> is a string that is delimited by the
characters "<" and ">" C<anyuncompress> will assume that it is an
I<output fileglob string>. The output is the list of files that match the
fileglob.

When C<$output_filename_or_reference> is an fileglob string,
C<$input_filename_or_reference> must also be a fileglob string. Anything
else is an error.

See L<File::GlobMapper|File::GlobMapper> for more details.

=back

If the C<$output_filename_or_reference> parameter is any other type,
C<undef> will be returned.

=head2 Notes

When C<$input_filename_or_reference> maps to multiple compressed
files/buffers and C<$output_filename_or_reference> is
a single file/buffer, after uncompression C<$output_filename_or_reference> will contain a
concatenation of all the uncompressed data from each of the input
files/buffers.

=head2 Optional Parameters

Unless specified below, the optional parameters for C<anyuncompress>,
C<OPTS>, are the same as those used with the OO interface defined in the
L</"Constructor Options"> section below.

=over 5

=item C<< AutoClose => 0|1 >>

This option applies to any input or output data streams to 
C<anyuncompress> that are filehandles.

If C<AutoClose> is specified, and the value is true, it will result in all
input and/or output filehandles being closed once C<anyuncompress> has
completed.

This parameter defaults to 0.

=item C<< BinModeOut => 0|1 >>

When writing to a file or filehandle, set C<binmode> before writing to the
file.

Defaults to 0.

=item C<< Append => 0|1 >>

The behaviour of this option is dependent on the type of output data
stream.

=over 5

=item * A Buffer

If C<Append> is enabled, all uncompressed data will be append to the end of
the output buffer. Otherwise the output buffer will be cleared before any
uncompressed data is written to it.

=item * A Filename

If C<Append> is enabled, the file will be opened in append mode. Otherwise
the contents of the file, if any, will be truncated before any uncompressed
data is written to it.

=item * A Filehandle

If C<Append> is enabled, the filehandle will be positioned to the end of
the file via a call to C<seek> before any uncompressed data is
written to it.  Otherwise the file pointer will not be moved.

=back

When C<Append> is specified, and set to true, it will I<append> all uncompressed 
data to the output data stream.

So when the output is a filehandle it will carry out a seek to the eof
before writing any uncompressed data. If the output is a filename, it will be opened for
appending. If the output is a buffer, all uncompressed data will be
appended to the existing buffer.

Conversely when C<Append> is not specified, or it is present and is set to
false, it will operate as follows.

When the output is a filename, it will truncate the contents of the file
before writing any uncompressed data. If the output is a filehandle
its position will not be changed. If the output is a buffer, it will be
wiped before any uncompressed data is output.

Defaults to 0.

=item C<< MultiStream => 0|1 >>

If the input file/buffer contains multiple compressed data streams, this
option will uncompress the whole lot as a single data stream.

Defaults to 0.

=item C<< TrailingData => $scalar >>

Returns the data, if any, that is present immediately after the compressed
data stream once uncompression is complete. 

This option can be used when there is useful information immediately
following the compressed data stream, and you don't know the length of the
compressed data stream.

If the input is a buffer, C<trailingData> will return everything from the
end of the compressed data stream to the end of the buffer.

If the input is a filehandle, C<trailingData> will return the data that is
left in the filehandle input buffer once the end of the compressed data
stream has been reached. You can then use the filehandle to read the rest
of the input file. 

Don't bother using C<trailingData> if the input is a filename.

If you know the length of the compressed data stream before you start
uncompressing, you can avoid having to use C<trailingData> by setting the
C<InputLength> option.

=back

=head2 Examples

To read the contents of the file C<file1.txt.Compressed> and write the
uncompressed data to the file C<file1.txt>.

    use strict ;
    use warnings ;
    use IO::Uncompress::AnyUncompress qw(anyuncompress $AnyUncompressError) ;

    my $input = "file1.txt.Compressed";
    my $output = "file1.txt";
    anyuncompress $input => $output
        or die "anyuncompress failed: $AnyUncompressError\n";

To read from an existing Perl filehandle, C<$input>, and write the
uncompressed data to a buffer, C<$buffer>.

    use strict ;
    use warnings ;
    use IO::Uncompress::AnyUncompress qw(anyuncompress $AnyUncompressError) ;
    use IO::File ;

    my $input = new IO::File "<file1.txt.Compressed"
        or die "Cannot open 'file1.txt.Compressed': $!\n" ;
    my $buffer ;
    anyuncompress $input => \$buffer 
        or die "anyuncompress failed: $AnyUncompressError\n";

To uncompress all files in the directory "/my/home" that match "*.txt.Compressed" and store the compressed data in the same directory

    use strict ;
    use warnings ;
    use IO::Uncompress::AnyUncompress qw(anyuncompress $AnyUncompressError) ;

    anyuncompress '</my/home/*.txt.Compressed>' => '</my/home/#1.txt>'
        or die "anyuncompress failed: $AnyUncompressError\n";

and if you want to compress each file one at a time, this will do the trick

    use strict ;
    use warnings ;
    use IO::Uncompress::AnyUncompress qw(anyuncompress $AnyUncompressError) ;

    for my $input ( glob "/my/home/*.txt.Compressed" )
    {
        my $output = $input;
        $output =~ s/.Compressed// ;
        anyuncompress $input => $output 
            or die "Error compressing '$input': $AnyUncompressError\n";
    }

=head1 OO Interface

=head2 Constructor

The format of the constructor for IO::Uncompress::AnyUncompress is shown below

    my $z = new IO::Uncompress::AnyUncompress $input [OPTS]
        or die "IO::Uncompress::AnyUncompress failed: $AnyUncompressError\n";

Returns an C<IO::Uncompress::AnyUncompress> object on success and undef on failure.
The variable C<$AnyUncompressError> will contain an error message on failure.

If you are running Perl 5.005 or better the object, C<$z>, returned from
IO::Uncompress::AnyUncompress can be used exactly like an L<IO::File|IO::File> filehandle.
This means that all normal input file operations can be carried out with
C<$z>.  For example, to read a line from a compressed file/buffer you can
use either of these forms

    $line = $z->getline();
    $line = <$z>;

The mandatory parameter C<$input> is used to determine the source of the
compressed data. This parameter can take one of three forms.

=over 5

=item A filename

If the C<$input> parameter is a scalar, it is assumed to be a filename. This
file will be opened for reading and the compressed data will be read from it.

=item A filehandle

If the C<$input> parameter is a filehandle, the compressed data will be
read from it.
The string '-' can be used as an alias for standard input.

=item A scalar reference 

If C<$input> is a scalar reference, the compressed data will be read from
C<$$input>.

=back

=head2 Constructor Options

The option names defined below are case insensitive and can be optionally
prefixed by a '-'.  So all of the following are valid

    -AutoClose
    -autoclose
    AUTOCLOSE
    autoclose

OPTS is a combination of the following options:

=over 5

=item C<< AutoClose => 0|1 >>

This option is only valid when the C<$input> parameter is a filehandle. If
specified, and the value is true, it will result in the file being closed once
either the C<close> method is called or the IO::Uncompress::AnyUncompress object is
destroyed.

This parameter defaults to 0.

=item C<< MultiStream => 0|1 >>

Allows multiple concatenated compressed streams to be treated as a single
compressed stream. Decompression will stop once either the end of the
file/buffer is reached, an error is encountered (premature eof, corrupt
compressed data) or the end of a stream is not immediately followed by the
start of another stream.

This parameter defaults to 0.

=item C<< Prime => $string >>

This option will uncompress the contents of C<$string> before processing the
input file/buffer.

This option can be useful when the compressed data is embedded in another
file/data structure and it is not possible to work out where the compressed
data begins without having to read the first few bytes. If this is the
case, the uncompression can be I<primed> with these bytes using this
option.

=item C<< Transparent => 0|1 >>

If this option is set and the input file/buffer is not compressed data,
the module will allow reading of it anyway.

In addition, if the input file/buffer does contain compressed data and
there is non-compressed data immediately following it, setting this option
will make this module treat the whole file/buffer as a single data stream.

This option defaults to 1.

=item C<< BlockSize => $num >>

When reading the compressed input data, IO::Uncompress::AnyUncompress will read it in
blocks of C<$num> bytes.

This option defaults to 4096.

=item C<< InputLength => $size >>

When present this option will limit the number of compressed bytes read
from the input file/buffer to C<$size>. This option can be used in the
situation where there is useful data directly after the compressed data
stream and you know beforehand the exact length of the compressed data
stream. 

This option is mostly used when reading from a filehandle, in which case
the file pointer will be left pointing to the first byte directly after the
compressed data stream.

This option defaults to off.

=item C<< Append => 0|1 >>

This option controls what the C<read> method does with uncompressed data.

If set to 1, all uncompressed data will be appended to the output parameter
of the C<read> method.

If set to 0, the contents of the output parameter of the C<read> method
will be overwritten by the uncompressed data.

Defaults to 0.

=item C<< Strict => 0|1 >>

This option controls whether the extra checks defined below are used when
carrying out the decompression. When Strict is on, the extra tests are
carried out, when Strict is off they are not.

The default for this option is off.

=item C<< RawInflate => 0|1 >>

When auto-detecting the compressed format, try to test for raw-deflate (RFC
1951) content using the C<IO::Uncompress::RawInflate> module. 

The reason this is not default behaviour is because RFC 1951 content can
only be detected by attempting to uncompress it. This process is error
prone and can result is false positives.

Defaults to 0.

=item C<< UnLzma => 0|1 >>

When auto-detecting the compressed format, try to test for lzma_alone
content using the C<IO::Uncompress::UnLzma> module. 

The reason this is not default behaviour is because lzma_alone content can
only be detected by attempting to uncompress it. This process is error
prone and can result is false positives.

Defaults to 0.

=back

=head2 Examples

TODO

=head1 Methods 

=head2 read

Usage is

    $status = $z->read($buffer)

Reads a block of compressed data (the size of the compressed block is
determined by the C<Buffer> option in the constructor), uncompresses it and
writes any uncompressed data into C<$buffer>. If the C<Append> parameter is
set in the constructor, the uncompressed data will be appended to the
C<$buffer> parameter. Otherwise C<$buffer> will be overwritten.

Returns the number of uncompressed bytes written to C<$buffer>, zero if eof
or a negative number on error.

=head2 read

Usage is

    $status = $z->read($buffer, $length)
    $status = $z->read($buffer, $length, $offset)

    $status = read($z, $buffer, $length)
    $status = read($z, $buffer, $length, $offset)

Attempt to read C<$length> bytes of uncompressed data into C<$buffer>.

The main difference between this form of the C<read> method and the
previous one, is that this one will attempt to return I<exactly> C<$length>
bytes. The only circumstances that this function will not is if end-of-file
or an IO error is encountered.

Returns the number of uncompressed bytes written to C<$buffer>, zero if eof
or a negative number on error.

=head2 getline

Usage is

    $line = $z->getline()
    $line = <$z>

Reads a single line. 

This method fully supports the use of the variable C<$/> (or
C<$INPUT_RECORD_SEPARATOR> or C<$RS> when C<English> is in use) to
determine what constitutes an end of line. Paragraph mode, record mode and
file slurp mode are all supported. 

=head2 getc

Usage is 

    $char = $z->getc()

Read a single character.

=head2 ungetc

Usage is

    $char = $z->ungetc($string)

=head2 getHeaderInfo

Usage is

    $hdr  = $z->getHeaderInfo();
    @hdrs = $z->getHeaderInfo();

This method returns either a hash reference (in scalar context) or a list
or hash references (in array context) that contains information about each
of the header fields in the compressed data stream(s).

=head2 tell

Usage is

    $z->tell()
    tell $z

Returns the uncompressed file offset.

=head2 eof

Usage is

    $z->eof();
    eof($z);

Returns true if the end of the compressed input stream has been reached.

=head2 seek

    $z->seek($position, $whence);
    seek($z, $position, $whence);

Provides a sub-set of the C<seek> functionality, with the restriction
that it is only legal to seek forward in the input file/buffer.
It is a fatal error to attempt to seek backward.

Note that the implementation of C<seek> in this module does not provide
true random access to a compressed file/buffer. It  works by uncompressing
data from the current offset in the file/buffer until it reaches the
uncompressed offset specified in the parameters to C<seek>. For very small
files this may be acceptable behaviour. For large files it may cause an
unacceptable delay.

The C<$whence> parameter takes one the usual values, namely SEEK_SET,
SEEK_CUR or SEEK_END.

Returns 1 on success, 0 on failure.

=head2 binmode

Usage is

    $z->binmode
    binmode $z ;

This is a noop provided for completeness.

=head2 opened

    $z->opened()

Returns true if the object currently refers to a opened file/buffer. 

=head2 autoflush

    my $prev = $z->autoflush()
    my $prev = $z->autoflush(EXPR)

If the C<$z> object is associated with a file or a filehandle, this method
returns the current autoflush setting for the underlying filehandle. If
C<EXPR> is present, and is non-zero, it will enable flushing after every
write/print operation.

If C<$z> is associated with a buffer, this method has no effect and always
returns C<undef>.

B<Note> that the special variable C<$|> B<cannot> be used to set or
retrieve the autoflush setting.

=head2 input_line_number

    $z->input_line_number()
    $z->input_line_number(EXPR)

Returns the current uncompressed line number. If C<EXPR> is present it has
the effect of setting the line number. Note that setting the line number
does not change the current position within the file/buffer being read.

The contents of C<$/> are used to determine what constitutes a line
terminator.

=head2 fileno

    $z->fileno()
    fileno($z)

If the C<$z> object is associated with a file or a filehandle, C<fileno>
will return the underlying file descriptor. Once the C<close> method is
called C<fileno> will return C<undef>.

If the C<$z> object is associated with a buffer, this method will return
C<undef>.

=head2 close

    $z->close() ;
    close $z ;

Closes the output file/buffer. 

For most versions of Perl this method will be automatically invoked if
the IO::Uncompress::AnyUncompress object is destroyed (either explicitly or by the
variable with the reference to the object going out of scope). The
exceptions are Perl versions 5.005 through 5.00504 and 5.8.0. In
these cases, the C<close> method will be called automatically, but
not until global destruction of all live objects when the program is
terminating.

Therefore, if you want your scripts to be able to run on all versions
of Perl, you should call C<close> explicitly and not rely on automatic
closing.

Returns true on success, otherwise 0.

If the C<AutoClose> option has been enabled when the IO::Uncompress::AnyUncompress
object was created, and the object is associated with a file, the
underlying file will also be closed.

=head2 nextStream

Usage is

    my $status = $z->nextStream();

Skips to the next compressed data stream in the input file/buffer. If a new
compressed data stream is found, the eof marker will be cleared and C<$.>
will be reset to 0.

Returns 1 if a new stream was found, 0 if none was found, and -1 if an
error was encountered.

=head2 trailingData

Usage is

    my $data = $z->trailingData();

Returns the data, if any, that is present immediately after the compressed
data stream once uncompression is complete. It only makes sense to call
this method once the end of the compressed data stream has been
encountered.

This option can be used when there is useful information immediately
following the compressed data stream, and you don't know the length of the
compressed data stream.

If the input is a buffer, C<trailingData> will return everything from the
end of the compressed data stream to the end of the buffer.

If the input is a filehandle, C<trailingData> will return the data that is
left in the filehandle input buffer once the end of the compressed data
stream has been reached. You can then use the filehandle to read the rest
of the input file. 

Don't bother using C<trailingData> if the input is a filename.

If you know the length of the compressed data stream before you start
uncompressing, you can avoid having to use C<trailingData> by setting the
C<InputLength> option in the constructor.

=head1 Importing 

No symbolic constants are required by this IO::Uncompress::AnyUncompress at present. 

=over 5

=item :all

Imports C<anyuncompress> and C<$AnyUncompressError>.
Same as doing this

    use IO::Uncompress::AnyUncompress qw(anyuncompress $AnyUncompressError) ;

=back

=head1 EXAMPLES

=head1 SEE ALSO

L<Compress::Zlib>, L<IO::Compress::Gzip>, L<IO::Uncompress::Gunzip>, L<IO::Compress::Deflate>, L<IO::Uncompress::Inflate>, L<IO::Compress::RawDeflate>, L<IO::Uncompress::RawInflate>, L<IO::Compress::Bzip2>, L<IO::Uncompress::Bunzip2>, L<IO::Compress::Lzma>, L<IO::Uncompress::UnLzma>, L<IO::Compress::Xz>, L<IO::Uncompress::UnXz>, L<IO::Compress::Lzop>, L<IO::Uncompress::UnLzop>, L<IO::Compress::Lzf>, L<IO::Uncompress::UnLzf>, L<IO::Uncompress::AnyInflate>

L<IO::Compress::FAQ|IO::Compress::FAQ>

L<File::GlobMapper|File::GlobMapper>, L<Archive::Zip|Archive::Zip>,
L<Archive::Tar|Archive::Tar>,
L<IO::Zlib|IO::Zlib>

=head1 AUTHOR

This module was written by Paul Marquess, F<pmqs@cpan.org>. 

=head1 MODIFICATION HISTORY

See the Changes file.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2014 Paul Marquess. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


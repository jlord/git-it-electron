package IO::Compress::Gzip ;

require 5.006 ;

use strict ;
use warnings;
use bytes;

require Exporter ;

use IO::Compress::RawDeflate 2.068 () ; 
use IO::Compress::Adapter::Deflate 2.068 ;

use IO::Compress::Base::Common  2.068 qw(:Status );
use IO::Compress::Gzip::Constants 2.068 ;
use IO::Compress::Zlib::Extra 2.068 ;

BEGIN
{
    if (defined &utf8::downgrade ) 
      { *noUTF8 = \&utf8::downgrade }
    else
      { *noUTF8 = sub {} }  
}

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS, %DEFLATE_CONSTANTS, $GzipError);

$VERSION = '2.068';
$GzipError = '' ;

@ISA    = qw(Exporter IO::Compress::RawDeflate);
@EXPORT_OK = qw( $GzipError gzip ) ;
%EXPORT_TAGS = %IO::Compress::RawDeflate::DEFLATE_CONSTANTS ;

push @{ $EXPORT_TAGS{all} }, @EXPORT_OK ;
Exporter::export_ok_tags('all');

sub new
{
    my $class = shift ;

    my $obj = IO::Compress::Base::Common::createSelfTiedObject($class, \$GzipError);

    $obj->_create(undef, @_);
}


sub gzip
{
    my $obj = IO::Compress::Base::Common::createSelfTiedObject(undef, \$GzipError);
    return $obj->_def(@_);
}

#sub newHeader
#{
#    my $self = shift ;
#    #return GZIP_MINIMUM_HEADER ;
#    return $self->mkHeader(*$self->{Got});
#}

sub getExtraParams
{
    my $self = shift ;

    return (
            # zlib behaviour
            $self->getZlibParams(),
           
            # Gzip header fields
            'minimal'   => [IO::Compress::Base::Common::Parse_boolean,   0],
            'comment'   => [IO::Compress::Base::Common::Parse_any,       undef],
            'name'      => [IO::Compress::Base::Common::Parse_any,       undef],
            'time'      => [IO::Compress::Base::Common::Parse_any,       undef],
            'textflag'  => [IO::Compress::Base::Common::Parse_boolean,   0],
            'headercrc' => [IO::Compress::Base::Common::Parse_boolean,   0],
            'os_code'   => [IO::Compress::Base::Common::Parse_unsigned,  $Compress::Raw::Zlib::gzip_os_code],
            'extrafield'=> [IO::Compress::Base::Common::Parse_any,       undef],
            'extraflags'=> [IO::Compress::Base::Common::Parse_any,       undef],

        );
}


sub ckParams
{
    my $self = shift ;
    my $got = shift ;

    # gzip always needs crc32
    $got->setValue('crc32' => 1);

    return 1
        if $got->getValue('merge') ;

    my $strict = $got->getValue('strict') ;


    {
        if (! $got->parsed('time') ) {
            # Modification time defaults to now.
            $got->setValue(time => time) ;
        }

        # Check that the Name & Comment don't have embedded NULLs
        # Also check that they only contain ISO 8859-1 chars.
        if ($got->parsed('name') && defined $got->getValue('name')) {
            my $name = $got->getValue('name');
                
            return $self->saveErrorString(undef, "Null Character found in Name",
                                                Z_DATA_ERROR)
                if $strict && $name =~ /\x00/ ;

            return $self->saveErrorString(undef, "Non ISO 8859-1 Character found in Name",
                                                Z_DATA_ERROR)
                if $strict && $name =~ /$GZIP_FNAME_INVALID_CHAR_RE/o ;
        }

        if ($got->parsed('comment') && defined $got->getValue('comment')) {
            my $comment = $got->getValue('comment');

            return $self->saveErrorString(undef, "Null Character found in Comment",
                                                Z_DATA_ERROR)
                if $strict && $comment =~ /\x00/ ;

            return $self->saveErrorString(undef, "Non ISO 8859-1 Character found in Comment",
                                                Z_DATA_ERROR)
                if $strict && $comment =~ /$GZIP_FCOMMENT_INVALID_CHAR_RE/o;
        }

        if ($got->parsed('os_code') ) {
            my $value = $got->getValue('os_code');

            return $self->saveErrorString(undef, "OS_Code must be between 0 and 255, got '$value'")
                if $value < 0 || $value > 255 ;
            
        }

        # gzip only supports Deflate at present
        $got->setValue('method' => Z_DEFLATED) ;

        if ( ! $got->parsed('extraflags')) {
            $got->setValue('extraflags' => 2) 
                if $got->getValue('level') == Z_BEST_COMPRESSION ;
            $got->setValue('extraflags' => 4) 
                if $got->getValue('level') == Z_BEST_SPEED ;
        }

        my $data = $got->getValue('extrafield') ;
        if (defined $data) {
            my $bad = IO::Compress::Zlib::Extra::parseExtraField($data, $strict, 1) ;
            return $self->saveErrorString(undef, "Error with ExtraField Parameter: $bad", Z_DATA_ERROR)
                if $bad ;

            $got->setValue('extrafield' => $data) ;
        }
    }

    return 1;
}

sub mkTrailer
{
    my $self = shift ;
    return pack("V V", *$self->{Compress}->crc32(), 
                       *$self->{UnCompSize}->get32bit());
}

sub getInverseClass
{
    return ('IO::Uncompress::Gunzip',
                \$IO::Uncompress::Gunzip::GunzipError);
}

sub getFileInfo
{
    my $self = shift ;
    my $params = shift;
    my $filename = shift ;

    return if IO::Compress::Base::Common::isaScalar($filename);

    my $defaultTime = (stat($filename))[9] ;

    $params->setValue('name' => $filename)
        if ! $params->parsed('name') ;

    $params->setValue('time' => $defaultTime) 
        if ! $params->parsed('time') ;
}


sub mkHeader
{
    my $self = shift ;
    my $param = shift ;

    # short-circuit if a minimal header is requested.
    return GZIP_MINIMUM_HEADER if $param->getValue('minimal') ;

    # METHOD
    my $method = $param->valueOrDefault('method', GZIP_CM_DEFLATED) ;

    # FLAGS
    my $flags       = GZIP_FLG_DEFAULT ;
    $flags |= GZIP_FLG_FTEXT    if $param->getValue('textflag') ;
    $flags |= GZIP_FLG_FHCRC    if $param->getValue('headercrc') ;
    $flags |= GZIP_FLG_FEXTRA   if $param->wantValue('extrafield') ;
    $flags |= GZIP_FLG_FNAME    if $param->wantValue('name') ;
    $flags |= GZIP_FLG_FCOMMENT if $param->wantValue('comment') ;
    
    # MTIME
    my $time = $param->valueOrDefault('time', GZIP_MTIME_DEFAULT) ;

    # EXTRA FLAGS
    my $extra_flags = $param->valueOrDefault('extraflags', GZIP_XFL_DEFAULT);

    # OS CODE
    my $os_code = $param->valueOrDefault('os_code', GZIP_OS_DEFAULT) ;


    my $out = pack("C4 V C C", 
            GZIP_ID1,   # ID1
            GZIP_ID2,   # ID2
            $method,    # Compression Method
            $flags,     # Flags
            $time,      # Modification Time
            $extra_flags, # Extra Flags
            $os_code,   # Operating System Code
            ) ;

    # EXTRA
    if ($flags & GZIP_FLG_FEXTRA) {
        my $extra = $param->getValue('extrafield') ;
        $out .= pack("v", length $extra) . $extra ;
    }

    # NAME
    if ($flags & GZIP_FLG_FNAME) {
        my $name .= $param->getValue('name') ;
        $name =~ s/\x00.*$//;
        $out .= $name ;
        # Terminate the filename with NULL unless it already is
        $out .= GZIP_NULL_BYTE 
            if !length $name or
               substr($name, 1, -1) ne GZIP_NULL_BYTE ;
    }

    # COMMENT
    if ($flags & GZIP_FLG_FCOMMENT) {
        my $comment .= $param->getValue('comment') ;
        $comment =~ s/\x00.*$//;
        $out .= $comment ;
        # Terminate the comment with NULL unless it already is
        $out .= GZIP_NULL_BYTE
            if ! length $comment or
               substr($comment, 1, -1) ne GZIP_NULL_BYTE;
    }

    # HEADER CRC
    $out .= pack("v", Compress::Raw::Zlib::crc32($out) & 0x00FF ) 
        if $param->getValue('headercrc') ;

    noUTF8($out);

    return $out ;
}

sub mkFinalTrailer
{
    return '';
}

1; 

__END__

=head1 NAME

IO::Compress::Gzip - Write RFC 1952 files/buffers
 
 

=head1 SYNOPSIS

    use IO::Compress::Gzip qw(gzip $GzipError) ;

    my $status = gzip $input => $output [,OPTS] 
        or die "gzip failed: $GzipError\n";

    my $z = new IO::Compress::Gzip $output [,OPTS]
        or die "gzip failed: $GzipError\n";

    $z->print($string);
    $z->printf($format, $string);
    $z->write($string);
    $z->syswrite($string [, $length, $offset]);
    $z->flush();
    $z->tell();
    $z->eof();
    $z->seek($position, $whence);
    $z->binmode();
    $z->fileno();
    $z->opened();
    $z->autoflush();
    $z->input_line_number();
    $z->newStream( [OPTS] );
    
    $z->deflateParams();
    
    $z->close() ;

    $GzipError ;

    # IO::File mode

    print $z $string;
    printf $z $format, $string;
    tell $z
    eof $z
    seek $z, $position, $whence
    binmode $z
    fileno $z
    close $z ;
    

=head1 DESCRIPTION

This module provides a Perl interface that allows writing compressed
data to files or buffer as defined in RFC 1952.

All the gzip headers defined in RFC 1952 can be created using
this module.

For reading RFC 1952 files/buffers, see the companion module 
L<IO::Uncompress::Gunzip|IO::Uncompress::Gunzip>.

=head1 Functional Interface

A top-level function, C<gzip>, is provided to carry out
"one-shot" compression between buffers and/or files. For finer
control over the compression process, see the L</"OO Interface">
section.

    use IO::Compress::Gzip qw(gzip $GzipError) ;

    gzip $input_filename_or_reference => $output_filename_or_reference [,OPTS] 
        or die "gzip failed: $GzipError\n";

The functional interface needs Perl5.005 or better.

=head2 gzip $input_filename_or_reference => $output_filename_or_reference [, OPTS]

C<gzip> expects at least two parameters,
C<$input_filename_or_reference> and C<$output_filename_or_reference>.

=head3 The C<$input_filename_or_reference> parameter

The parameter, C<$input_filename_or_reference>, is used to define the
source of the uncompressed data. 

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
contains valid filenames before any data is compressed.

=item An Input FileGlob string

If C<$input_filename_or_reference> is a string that is delimited by the
characters "<" and ">" C<gzip> will assume that it is an 
I<input fileglob string>. The input is the list of files that match the 
fileglob.

See L<File::GlobMapper|File::GlobMapper> for more details.

=back

If the C<$input_filename_or_reference> parameter is any other type,
C<undef> will be returned.

In addition, if C<$input_filename_or_reference> is a simple filename, 
the default values for
the C<Name> and C<Time> options will be sourced from that file.

If you do not want to use these defaults they can be overridden by
explicitly setting the C<Name> and C<Time> options or by setting the
C<Minimal> parameter.

=head3 The C<$output_filename_or_reference> parameter

The parameter C<$output_filename_or_reference> is used to control the
destination of the compressed data. This parameter can take one of
these forms.

=over 5

=item A filename

If the C<$output_filename_or_reference> parameter is a simple scalar, it is
assumed to be a filename.  This file will be opened for writing and the 
compressed data will be written to it.

=item A filehandle

If the C<$output_filename_or_reference> parameter is a filehandle, the
compressed data will be written to it.  The string '-' can be used as
an alias for standard output.

=item A scalar reference 

If C<$output_filename_or_reference> is a scalar reference, the
compressed data will be stored in C<$$output_filename_or_reference>.

=item An Array Reference

If C<$output_filename_or_reference> is an array reference, 
the compressed data will be pushed onto the array.

=item An Output FileGlob

If C<$output_filename_or_reference> is a string that is delimited by the
characters "<" and ">" C<gzip> will assume that it is an
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

When C<$input_filename_or_reference> maps to multiple files/buffers and
C<$output_filename_or_reference> is a single
file/buffer the input files/buffers will be stored
in C<$output_filename_or_reference> as a concatenated series of compressed data streams.

=head2 Optional Parameters

Unless specified below, the optional parameters for C<gzip>,
C<OPTS>, are the same as those used with the OO interface defined in the
L</"Constructor Options"> section below.

=over 5

=item C<< AutoClose => 0|1 >>

This option applies to any input or output data streams to 
C<gzip> that are filehandles.

If C<AutoClose> is specified, and the value is true, it will result in all
input and/or output filehandles being closed once C<gzip> has
completed.

This parameter defaults to 0.

=item C<< BinModeIn => 0|1 >>

When reading from a file or filehandle, set C<binmode> before reading.

Defaults to 0.

=item C<< Append => 0|1 >>

The behaviour of this option is dependent on the type of output data
stream.

=over 5

=item * A Buffer

If C<Append> is enabled, all compressed data will be append to the end of
the output buffer. Otherwise the output buffer will be cleared before any
compressed data is written to it.

=item * A Filename

If C<Append> is enabled, the file will be opened in append mode. Otherwise
the contents of the file, if any, will be truncated before any compressed
data is written to it.

=item * A Filehandle

If C<Append> is enabled, the filehandle will be positioned to the end of
the file via a call to C<seek> before any compressed data is
written to it.  Otherwise the file pointer will not be moved.

=back

When C<Append> is specified, and set to true, it will I<append> all compressed 
data to the output data stream.

So when the output is a filehandle it will carry out a seek to the eof
before writing any compressed data. If the output is a filename, it will be opened for
appending. If the output is a buffer, all compressed data will be
appended to the existing buffer.

Conversely when C<Append> is not specified, or it is present and is set to
false, it will operate as follows.

When the output is a filename, it will truncate the contents of the file
before writing any compressed data. If the output is a filehandle
its position will not be changed. If the output is a buffer, it will be
wiped before any compressed data is output.

Defaults to 0.

=back

=head2 Examples

To read the contents of the file C<file1.txt> and write the compressed
data to the file C<file1.txt.gz>.

    use strict ;
    use warnings ;
    use IO::Compress::Gzip qw(gzip $GzipError) ;

    my $input = "file1.txt";
    gzip $input => "$input.gz"
        or die "gzip failed: $GzipError\n";

To read from an existing Perl filehandle, C<$input>, and write the
compressed data to a buffer, C<$buffer>.

    use strict ;
    use warnings ;
    use IO::Compress::Gzip qw(gzip $GzipError) ;
    use IO::File ;

    my $input = new IO::File "<file1.txt"
        or die "Cannot open 'file1.txt': $!\n" ;
    my $buffer ;
    gzip $input => \$buffer 
        or die "gzip failed: $GzipError\n";

To compress all files in the directory "/my/home" that match "*.txt"
and store the compressed data in the same directory

    use strict ;
    use warnings ;
    use IO::Compress::Gzip qw(gzip $GzipError) ;

    gzip '</my/home/*.txt>' => '<*.gz>'
        or die "gzip failed: $GzipError\n";

and if you want to compress each file one at a time, this will do the trick

    use strict ;
    use warnings ;
    use IO::Compress::Gzip qw(gzip $GzipError) ;

    for my $input ( glob "/my/home/*.txt" )
    {
        my $output = "$input.gz" ;
        gzip $input => $output 
            or die "Error compressing '$input': $GzipError\n";
    }

=head1 OO Interface

=head2 Constructor

The format of the constructor for C<IO::Compress::Gzip> is shown below

    my $z = new IO::Compress::Gzip $output [,OPTS]
        or die "IO::Compress::Gzip failed: $GzipError\n";

It returns an C<IO::Compress::Gzip> object on success and undef on failure. 
The variable C<$GzipError> will contain an error message on failure.

If you are running Perl 5.005 or better the object, C<$z>, returned from 
IO::Compress::Gzip can be used exactly like an L<IO::File|IO::File> filehandle. 
This means that all normal output file operations can be carried out 
with C<$z>. 
For example, to write to a compressed file/buffer you can use either of 
these forms

    $z->print("hello world\n");
    print $z "hello world\n";

The mandatory parameter C<$output> is used to control the destination
of the compressed data. This parameter can take one of these forms.

=over 5

=item A filename

If the C<$output> parameter is a simple scalar, it is assumed to be a
filename. This file will be opened for writing and the compressed data
will be written to it.

=item A filehandle

If the C<$output> parameter is a filehandle, the compressed data will be
written to it.
The string '-' can be used as an alias for standard output.

=item A scalar reference 

If C<$output> is a scalar reference, the compressed data will be stored
in C<$$output>.

=back

If the C<$output> parameter is any other type, C<IO::Compress::Gzip>::new will
return undef.

=head2 Constructor Options

C<OPTS> is any combination of the following options:

=over 5

=item C<< AutoClose => 0|1 >>

This option is only valid when the C<$output> parameter is a filehandle. If
specified, and the value is true, it will result in the C<$output> being
closed once either the C<close> method is called or the C<IO::Compress::Gzip>
object is destroyed.

This parameter defaults to 0.

=item C<< Append => 0|1 >>

Opens C<$output> in append mode. 

The behaviour of this option is dependent on the type of C<$output>.

=over 5

=item * A Buffer

If C<$output> is a buffer and C<Append> is enabled, all compressed data
will be append to the end of C<$output>. Otherwise C<$output> will be
cleared before any data is written to it.

=item * A Filename

If C<$output> is a filename and C<Append> is enabled, the file will be
opened in append mode. Otherwise the contents of the file, if any, will be
truncated before any compressed data is written to it.

=item * A Filehandle

If C<$output> is a filehandle, the file pointer will be positioned to the
end of the file via a call to C<seek> before any compressed data is written
to it.  Otherwise the file pointer will not be moved.

=back

This parameter defaults to 0.

=item C<< Merge => 0|1 >>

This option is used to compress input data and append it to an existing
compressed data stream in C<$output>. The end result is a single compressed
data stream stored in C<$output>. 

It is a fatal error to attempt to use this option when C<$output> is not an
RFC 1952 data stream.

There are a number of other limitations with the C<Merge> option:

=over 5 

=item 1

This module needs to have been built with zlib 1.2.1 or better to work. A
fatal error will be thrown if C<Merge> is used with an older version of
zlib.  

=item 2

If C<$output> is a file or a filehandle, it must be seekable.

=back

This parameter defaults to 0.

=item -Level 

Defines the compression level used by zlib. The value should either be
a number between 0 and 9 (0 means no compression and 9 is maximum
compression), or one of the symbolic constants defined below.

   Z_NO_COMPRESSION
   Z_BEST_SPEED
   Z_BEST_COMPRESSION
   Z_DEFAULT_COMPRESSION

The default is Z_DEFAULT_COMPRESSION.

Note, these constants are not imported by C<IO::Compress::Gzip> by default.

    use IO::Compress::Gzip qw(:strategy);
    use IO::Compress::Gzip qw(:constants);
    use IO::Compress::Gzip qw(:all);

=item -Strategy 

Defines the strategy used to tune the compression. Use one of the symbolic
constants defined below.

   Z_FILTERED
   Z_HUFFMAN_ONLY
   Z_RLE
   Z_FIXED
   Z_DEFAULT_STRATEGY

The default is Z_DEFAULT_STRATEGY.

=item C<< Minimal => 0|1 >>

If specified, this option will force the creation of the smallest possible
compliant gzip header (which is exactly 10 bytes long) as defined in
RFC 1952.

See the section titled "Compliance" in RFC 1952 for a definition 
of the values used for the fields in the gzip header.

All other parameters that control the content of the gzip header will
be ignored if this parameter is set to 1.

This parameter defaults to 0.

=item C<< Comment => $comment >>

Stores the contents of C<$comment> in the COMMENT field in
the gzip header.
By default, no comment field is written to the gzip file.

If the C<-Strict> option is enabled, the comment can only consist of ISO
8859-1 characters plus line feed.

If the C<-Strict> option is disabled, the comment field can contain any
character except NULL. If any null characters are present, the field
will be truncated at the first NULL.

=item C<< Name => $string >>

Stores the contents of C<$string> in the gzip NAME header field. If
C<Name> is not specified, no gzip NAME field will be created.

If the C<-Strict> option is enabled, C<$string> can only consist of ISO
8859-1 characters.

If C<-Strict> is disabled, then C<$string> can contain any character
except NULL. If any null characters are present, the field will be
truncated at the first NULL.

=item C<< Time => $number >>

Sets the MTIME field in the gzip header to $number.

This field defaults to the time the C<IO::Compress::Gzip> object was created
if this option is not specified.

=item C<< TextFlag => 0|1 >>

This parameter controls the setting of the FLG.FTEXT bit in the gzip
header. It is used to signal that the data stored in the gzip file/buffer
is probably text.

The default is 0. 

=item C<< HeaderCRC => 0|1 >>

When true this parameter will set the FLG.FHCRC bit to 1 in the gzip header
and set the CRC16 header field to the CRC of the complete gzip header
except the CRC16 field itself.

B<Note> that gzip files created with the C<HeaderCRC> flag set to 1 cannot
be read by most, if not all, of the standard gunzip utilities, most
notably gzip version 1.2.4. You should therefore avoid using this option if
you want to maximize the portability of your gzip files.

This parameter defaults to 0.

=item C<< OS_Code => $value >>

Stores C<$value> in the gzip OS header field. A number between 0 and 255 is
valid.

If not specified, this parameter defaults to the OS code of the Operating
System this module was built on. The value 3 is used as a catch-all for all
Unix variants and unknown Operating Systems.

=item C<< ExtraField => $data >>

This parameter allows additional metadata to be stored in the ExtraField in
the gzip header. An RFC 1952 compliant ExtraField consists of zero or more
subfields. Each subfield consists of a two byte header followed by the
subfield data.

The list of subfields can be supplied in any of the following formats

    -ExtraField => [$id1, $data1,
                    $id2, $data2,
                     ...
                   ]
    -ExtraField => [ [$id1 => $data1],
                     [$id2 => $data2],
                     ...
                   ]
    -ExtraField => { $id1 => $data1,
                     $id2 => $data2,
                     ...
                   }

Where C<$id1>, C<$id2> are two byte subfield ID's. The second byte of
the ID cannot be 0, unless the C<Strict> option has been disabled.

If you use the hash syntax, you have no control over the order in which
the ExtraSubFields are stored, plus you cannot have SubFields with
duplicate ID.

Alternatively the list of subfields can by supplied as a scalar, thus

    -ExtraField => $rawdata

If you use the raw format, and the C<Strict> option is enabled,
C<IO::Compress::Gzip> will check that C<$rawdata> consists of zero or more
conformant sub-fields. When C<Strict> is disabled, C<$rawdata> can
consist of any arbitrary byte stream.

The maximum size of the Extra Field 65535 bytes.

=item C<< ExtraFlags => $value >>

Sets the XFL byte in the gzip header to C<$value>.

If this option is not present, the value stored in XFL field will be
determined by the setting of the C<Level> option.

If C<< Level => Z_BEST_SPEED >> has been specified then XFL is set to 2.
If C<< Level => Z_BEST_COMPRESSION >> has been specified then XFL is set to 4.
Otherwise XFL is set to 0.

=item C<< Strict => 0|1 >>

C<Strict> will optionally police the values supplied with other options
to ensure they are compliant with RFC1952.

This option is enabled by default.

If C<Strict> is enabled the following behaviour will be policed:

=over 5

=item * 

The value supplied with the C<Name> option can only contain ISO 8859-1
characters.

=item * 

The value supplied with the C<Comment> option can only contain ISO 8859-1
characters plus line-feed.

=item *

The values supplied with the C<-Name> and C<-Comment> options cannot
contain multiple embedded nulls.

=item * 

If an C<ExtraField> option is specified and it is a simple scalar,
it must conform to the sub-field structure as defined in RFC 1952.

=item * 

If an C<ExtraField> option is specified the second byte of the ID will be
checked in each subfield to ensure that it does not contain the reserved
value 0x00.

=back

When C<Strict> is disabled the following behaviour will be policed:

=over 5

=item * 

The value supplied with C<-Name> option can contain
any character except NULL.

=item * 

The value supplied with C<-Comment> option can contain any character
except NULL.

=item *

The values supplied with the C<-Name> and C<-Comment> options can contain
multiple embedded nulls. The string written to the gzip header will
consist of the characters up to, but not including, the first embedded
NULL.

=item * 

If an C<ExtraField> option is specified and it is a simple scalar, the
structure will not be checked. The only error is if the length is too big.

=item * 

The ID header in an C<ExtraField> sub-field can consist of any two bytes.

=back

=back

=head2 Examples

TODO

=head1 Methods 

=head2 print

Usage is

    $z->print($data)
    print $z $data

Compresses and outputs the contents of the C<$data> parameter. This
has the same behaviour as the C<print> built-in.

Returns true if successful.

=head2 printf

Usage is

    $z->printf($format, $data)
    printf $z $format, $data

Compresses and outputs the contents of the C<$data> parameter.

Returns true if successful.

=head2 syswrite

Usage is

    $z->syswrite $data
    $z->syswrite $data, $length
    $z->syswrite $data, $length, $offset

Compresses and outputs the contents of the C<$data> parameter.

Returns the number of uncompressed bytes written, or C<undef> if
unsuccessful.

=head2 write

Usage is

    $z->write $data
    $z->write $data, $length
    $z->write $data, $length, $offset

Compresses and outputs the contents of the C<$data> parameter.

Returns the number of uncompressed bytes written, or C<undef> if
unsuccessful.

=head2 flush

Usage is

    $z->flush;
    $z->flush($flush_type);

Flushes any pending compressed data to the output file/buffer.

This method takes an optional parameter, C<$flush_type>, that controls
how the flushing will be carried out. By default the C<$flush_type>
used is C<Z_FINISH>. Other valid values for C<$flush_type> are
C<Z_NO_FLUSH>, C<Z_SYNC_FLUSH>, C<Z_FULL_FLUSH> and C<Z_BLOCK>. It is
strongly recommended that you only set the C<flush_type> parameter if
you fully understand the implications of what it does - overuse of C<flush>
can seriously degrade the level of compression achieved. See the C<zlib>
documentation for details.

Returns true on success.

=head2 tell

Usage is

    $z->tell()
    tell $z

Returns the uncompressed file offset.

=head2 eof

Usage is

    $z->eof();
    eof($z);

Returns true if the C<close> method has been called.

=head2 seek

    $z->seek($position, $whence);
    seek($z, $position, $whence);

Provides a sub-set of the C<seek> functionality, with the restriction
that it is only legal to seek forward in the output file/buffer.
It is a fatal error to attempt to seek backward.

Empty parts of the file/buffer will have NULL (0x00) bytes written to them.

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

This method always returns C<undef> when compressing. 

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

Flushes any pending compressed data and then closes the output file/buffer. 

For most versions of Perl this method will be automatically invoked if
the IO::Compress::Gzip object is destroyed (either explicitly or by the
variable with the reference to the object going out of scope). The
exceptions are Perl versions 5.005 through 5.00504 and 5.8.0. In
these cases, the C<close> method will be called automatically, but
not until global destruction of all live objects when the program is
terminating.

Therefore, if you want your scripts to be able to run on all versions
of Perl, you should call C<close> explicitly and not rely on automatic
closing.

Returns true on success, otherwise 0.

If the C<AutoClose> option has been enabled when the IO::Compress::Gzip
object was created, and the object is associated with a file, the
underlying file will also be closed.

=head2 newStream([OPTS])

Usage is

    $z->newStream( [OPTS] )

Closes the current compressed data stream and starts a new one.

OPTS consists of any of the options that are available when creating
the C<$z> object.

See the L</"Constructor Options"> section for more details.

=head2 deflateParams

Usage is

    $z->deflateParams

TODO

=head1 Importing 

A number of symbolic constants are required by some methods in 
C<IO::Compress::Gzip>. None are imported by default.

=over 5

=item :all

Imports C<gzip>, C<$GzipError> and all symbolic
constants that can be used by C<IO::Compress::Gzip>. Same as doing this

    use IO::Compress::Gzip qw(gzip $GzipError :constants) ;

=item :constants

Import all symbolic constants. Same as doing this

    use IO::Compress::Gzip qw(:flush :level :strategy) ;

=item :flush

These symbolic constants are used by the C<flush> method.

    Z_NO_FLUSH
    Z_PARTIAL_FLUSH
    Z_SYNC_FLUSH
    Z_FULL_FLUSH
    Z_FINISH
    Z_BLOCK

=item :level

These symbolic constants are used by the C<Level> option in the constructor.

    Z_NO_COMPRESSION
    Z_BEST_SPEED
    Z_BEST_COMPRESSION
    Z_DEFAULT_COMPRESSION

=item :strategy

These symbolic constants are used by the C<Strategy> option in the constructor.

    Z_FILTERED
    Z_HUFFMAN_ONLY
    Z_RLE
    Z_FIXED
    Z_DEFAULT_STRATEGY

    
    

=back

=head1 EXAMPLES

=head2 Apache::GZip Revisited

See L<IO::Compress::FAQ|IO::Compress::FAQ/"Apache::GZip Revisited">

=head2 Working with Net::FTP

See L<IO::Compress::FAQ|IO::Compress::FAQ/"Compressed files and Net::FTP">

=head1 SEE ALSO

L<Compress::Zlib>, L<IO::Uncompress::Gunzip>, L<IO::Compress::Deflate>, L<IO::Uncompress::Inflate>, L<IO::Compress::RawDeflate>, L<IO::Uncompress::RawInflate>, L<IO::Compress::Bzip2>, L<IO::Uncompress::Bunzip2>, L<IO::Compress::Lzma>, L<IO::Uncompress::UnLzma>, L<IO::Compress::Xz>, L<IO::Uncompress::UnXz>, L<IO::Compress::Lzop>, L<IO::Uncompress::UnLzop>, L<IO::Compress::Lzf>, L<IO::Uncompress::UnLzf>, L<IO::Uncompress::AnyInflate>, L<IO::Uncompress::AnyUncompress>

L<IO::Compress::FAQ|IO::Compress::FAQ>

L<File::GlobMapper|File::GlobMapper>, L<Archive::Zip|Archive::Zip>,
L<Archive::Tar|Archive::Tar>,
L<IO::Zlib|IO::Zlib>

For RFC 1950, 1951 and 1952 see 
F<http://www.faqs.org/rfcs/rfc1950.html>,
F<http://www.faqs.org/rfcs/rfc1951.html> and
F<http://www.faqs.org/rfcs/rfc1952.html>

The I<zlib> compression library was written by Jean-loup Gailly
F<gzip@prep.ai.mit.edu> and Mark Adler F<madler@alumni.caltech.edu>.

The primary site for the I<zlib> compression library is
F<http://www.zlib.org>.

The primary site for gzip is F<http://www.gzip.org>.

=head1 AUTHOR

This module was written by Paul Marquess, F<pmqs@cpan.org>. 

=head1 MODIFICATION HISTORY

See the Changes file.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2014 Paul Marquess. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


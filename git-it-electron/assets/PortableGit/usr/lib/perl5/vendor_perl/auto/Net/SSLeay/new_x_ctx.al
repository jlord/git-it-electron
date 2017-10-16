# NOTE: Derived from blib/lib/Net/SSLeay.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Net::SSLeay;

#line 938 "blib/lib/Net/SSLeay.pm (autosplit into blib/lib/auto/Net/SSLeay/new_x_ctx.al)"
sub new_x_ctx {
    if ($ssl_version == 2)  {
	unless (exists &Net::SSLeay::CTX_v2_new) {
	    warn "ssl_version has been set to 2, but this version of OpenSSL has been compiled without SSLv2 support";
	    return undef;
	}
	$ctx = CTX_v2_new();
    }
    elsif ($ssl_version == 3)  { $ctx = CTX_v3_new(); }
    elsif ($ssl_version == 10) { $ctx = CTX_tlsv1_new(); }
    elsif ($ssl_version == 11) {
	unless (exists &Net::SSLeay::CTX_tlsv1_1_new) {
	    warn "ssl_version has been set to 11, but this version of OpenSSL has been compiled without TLSv1.1 support";
	    return undef;
	}
        $ctx = CTX_tlsv1_1_new;
    }
    elsif ($ssl_version == 12) {
	unless (exists &Net::SSLeay::CTX_tlsv1_2_new) {
	    warn "ssl_version has been set to 12, but this version of OpenSSL has been compiled without TLSv1.2 support";
	    return undef;
	}
        $ctx = CTX_tlsv1_2_new;
    }
    else                       { $ctx = CTX_new(); }
    return $ctx;
}

# end of Net::SSLeay::new_x_ctx
1;

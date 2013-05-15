package VarExpand::Plugin;

use strict;
use MT;

my @permit = qw( rand abs sin cos hex oct );

# MTSetVarFormula tag
sub setvar_formula {
    my ($ctx, $args) = @_;

    my $expr = $args->{formula} || '';
    return '' if (!$expr);

    my $safe = $ctx->{__safe_compartment};
    if (!$safe) {
        $safe = eval { require Safe; new Safe; }
            or return $ctx->error("Cannot evaluate expression [$expr]: Perl 'Safe' module is required.");
        $safe->permit(@permit);
        $ctx->{__safe_compartment} = $safe;
    }
    my $vars = $ctx->{__stash}{vars};
    my $ns = $safe->root;
    {
        no strict 'refs';
        foreach my $v (keys %$vars) {
            ${ $ns . '::' . $v } = $vars->{$v};
        }
    }
    my $res = $safe->reval($expr);
    if ($@) {
        return $ctx->error("Error in expression [$expr]: $@");
    }
    if (lc($ctx->stash('tag')) eq 'setvarformula') {
        my $name = $args->{name} || '';
        return '' if (!$name);
        $args->{value} = $res;
        $ctx->stash('tag', 'setvar');
        $ctx->tag('setvar', $args);
        return '';
    }
    else {
        return $res;
    }
}

# MTGetVarFunction tag
sub getvar_function {
    my ($ctx, $args) = @_;

    my $vars = $ctx->{__stash}{vars} ||= {};
    my @names = keys %$args;
    my @var_names;
    push @var_names, lc $_ for @names;
    local @{$vars}{@var_names};
    $vars->{lc($_)} = $args->{$_} for @names;
    $ctx->stash('tag', 'getvar');
    $ctx->tag('getvar', $args);
}

1;

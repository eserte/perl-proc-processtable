#!/usr/bin/perl -w

use strict;
use Test::More;

my %supported_os = map {($_,1)} qw(freebsd linux);

if (!$supported_os{$^O}) {
    plan skip_all => "This test is not supported under $^O";
    exit 0;
}

# Capabilities
use constant CAN_GROUPS => $^O eq 'freebsd';
use constant CAN_ONPRO  => $^O eq 'freebsd';
use constant CAN_NUMTHR => $^O eq 'freebsd';

plan tests => 18;

use Proc::ProcessTable;

my $ps = Proc::ProcessTable->new;
isa_ok $ps, 'Proc::ProcessTable';

my $this_proc;
for my $proc (@{ $ps->table }) {
    if ($proc->pid == $$) {
	$this_proc = $proc;
	last;
    }
}

isa_ok $this_proc, 'Proc::ProcessTable::Process';

is $this_proc->pid, $$, 'pid';
is $this_proc->ppid, getppid, 'ppid';
is $this_proc->pgrp, getpgrp, 'pgrp';

is $this_proc->uid, $<, 'uid';
is $this_proc->euid, $>, 'euid';

{
    my @groups = split / /, $(;
    my $gid = shift @groups;
    is $this_proc->gid, $gid, 'gid';
 SKIP: {
	skip "groups not supported", 1 if !CAN_GROUPS;
	is_deeply $this_proc->groups, [@groups], 'groups';
    }
}

cmp_ok int($this_proc->start), "<=", time, 'start time';

# XXX "+0" shouldn't be necessary here!
is $this_proc->ctime+0, 0, 'no child time';
is $this_proc->cutime+0, 0;
is $this_proc->cstime+0, 0;

is $this_proc->state, 'run';
SKIP: {
    skip "onpro not supported", 1 if !CAN_ONPRO;
    isnt $this_proc->onpro, undef, 'we are on a CPU';
}
SKIP: {
    skip "numthr not supported", 1 if !CAN_NUMTHR;
    is $this_proc->numthr, 1, 'no threads';
}

like $this_proc->cmndline, qr{\Q$^X}, 'found interpreter name in cmndline';
like $this_proc->cmndline, qr{\Q$0}, 'found test script name in cmndline';

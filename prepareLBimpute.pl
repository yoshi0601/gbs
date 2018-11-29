while ($line = <STDIN>) {

	chomp $line;
	if ($line =~ /^#/) {
		print "$line\n";
		next;
	}

	$flag = 0;
	@data = split(/\t/,$line);
	if ($data[4] eq ".") {
		$flag =1;
	} elsif ($data[4] =~ /,/) {
		$flag = 1;
	} elsif ($data[3] =~ /-/) {
		$flag = 1;
	} else {
		# 問題なければさらにADに問題がないかを検査する
		for (my $i=9;$i<scalar(@data);$i++) {
			@data2 = split(/:/,$data[$i]);
			$flag = 1 if ($data2[0] eq './1' or $data2[0] eq './0' or $data2[0] eq '0/.' or $data2[0] eq '1/.');
			if ($data2[1] =~ /,/) {
		
			} else {
				$flag = 1;
			}
		}
	}

	# ADフラグに基づいて、その行を印刷するかを決める。
	if ($flag == 0) {
		print "$line\n";
	} elsif ($flag == 1) {
		next;
	}

}

	

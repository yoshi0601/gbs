#!/usr/bin/perl

use strict;
use warnings;

# User settings;
my $parent1_name = "T65"; # Parent1 name for genotype A homozygotes.
my $parent2_name = "PTB33"; # Parent2 name for genotype B homozygotes.
my $exclude_list=""; # 
my $display_parent = "ON"; # Here you can chose ON or OFF to include the parents genotypes.


###########################
# BODY
my @exclude_list;
if (@exclude_list = split(/,/,$exclude_list)) {
	# nothing to do
} else {
	push(@exclude_list,$exclude_list) unless ($exclude_list eq "");
};

my @parent1_name;
if (@parent1_name = split(/,/,$parent1_name)) {
	# nothing to do
} else {
	push(@parent1_name,$parent1_name) unless ($parent1_name eq "");
};

my @parent2_name;
if (@parent2_name = split(/,/,$parent2_name)) {
	# nothing to do
} else {
	push(@parent2_name,$parent2_name) unless ($parent2_name eq "");
};

#####################################
# Read polymorphic sites between parents
my $parent_polymorphic_file = $ARGV[0];
open (PARENTS,"<$parent_polymorphic_file") || die "Parent file could not be opened.\n";
my @parent_header;
my @parent_parent1_pos;
my @parent_parent2_pos;
my %parent_hash;


while (<PARENTS>) {
	chomp;
	my @file = split(/\t/, $_);
	my $list_length = @file;
	if($file[0] eq 'rs#'){
		my $counter = 0;
		foreach my $i (@file) {
			foreach my $j (@parent1_name) {
				if ($i eq $j) {
					print "$j is included as the parent1.\n";
					push(@parent_parent1_pos,$counter);
				} else {
					#print "$j is NOT inculded as the parent1. \n";
				};
			};
			
			foreach my $j (@parent2_name) {
				if ($i eq $j) {	
					print "$j is included as the parent2.\n";
					push(@parent_parent2_pos,$counter);
				} else { 
					#print "$j is NOT included as the parent2. \n";
				};
			};
			$counter++

		};
	} else {
		my $snp_name = $file[0]; #marker name
		my $snp_bimorphism = $file[1]; # bimorphism
		my $chr_num = $file[2]; #chromosome
		my $position = $file[3]; #position in bp
		my $column_num = 0;
		my @parent1_geno;
		my @parent2_geno;

		# consensus genotype for the parent1
		foreach my $i (@parent_parent1_pos) {
			my $one_letter_genotype = &one2two_letters($snp_bimorphism,$file[$i]);
			push(@parent1_geno,$one_letter_genotype);
		};
		my $parent1_geno_consensus = &consensus_genotype(@parent1_geno);
#print "Parent1: @parent1_geno\t$parent1_geno_consensus\n";
		next if (!defined($parent1_geno_consensus));
		next if ($parent1_geno_consensus eq "multiple" or $parent1_geno_consensus eq "NN");
		

		# consensus genotype for the parent2
		foreach my $i (@parent_parent2_pos) {
			my $one_letter_genotype = &one2two_letters($snp_bimorphism,$file[$i]);
			push(@parent2_geno,$one_letter_genotype);
		};
		my $parent2_geno_consensus = &consensus_genotype(@parent2_geno);
#print "Parent2: @parent2_geno\t$parent2_geno_consensus\n";
		next if (!defined($parent2_geno_consensus));
		next if ($parent2_geno_consensus eq "multiple" or $parent2_geno_consensus eq "NN");

		$parent_hash{$snp_name} = [$parent1_geno_consensus,$parent2_geno_consensus];
	};
};

#for debug
#print @parent_parent1_pos;

#for debug
#foreach my $cite (sort(keys(%parent_hash))) {
#	print "$cite\t@{$parent_hash{$cite}}\n";
#
#};


# Initialization
my @header;
my @exclude_numbers = (1,4,5,6,7,8,9,10);
my @parent1_pos;
my @parent2_pos;
my %fh = &cp_open();

while(<stdin>){
	chomp;
	my @oneline = split(/\t/, $_);
	my $crosstype;	
	# Handling headers. 
	# When the user set $diplay_parent = "OFF", columns for the $parent1_name 
	# and $parent2_name will be not shown in output. 
	if($oneline[0] eq 'rs#'){
		my $counter = 0;
		$crosstype = "header";

		foreach my $i (@oneline) {
		
			# Checking $parent1_name
			# Column numbers of $parent1_name are added to the @exclude_numberes.
			foreach my $j (@parent1_name) {
				if ($i eq $j) {
					#push(@parent1_pos,$counter);	
					push(@exclude_numbers,$counter) if $display_parent eq "OFF";
				};
			};
		
			# Checking $parent2_name
			# Column numbers of $parent2_name are added to the @exclude_numberes.
			foreach my $j (@parent2_name) {
				if ($i eq $j) {
					#push(@parent2_pos,$counter);
					push(@exclude_numbers,$counter) if $display_parent eq "OFF";
				};
			};

			# User-defined column for excluding at $exclude_list will be added to the @exclude_numberes.
			foreach my $j (@exclude_list) {
				if ($i eq $j) {
					push(@exclude_numbers,$counter);
				};
			};
			$counter++
		};

	# Handling genotype data
	} else {
		
		my ($snp_name,$alleles,$chr_num,$position) = ($oneline[0],$oneline[1],$oneline[2],$oneline[3]); 
		my $column_num = 0;
		my ($allele1, $allele2) = split(/\//,$alleles);

		# Judgement for the crosstypes from parental genotypes
		my ($parent1_geno,$parent2_geno);
		if ($parent_hash{$snp_name} eq "") {
			next;
		} else {
			($parent1_geno,$parent2_geno) = @{$parent_hash{$snp_name}};
		};

		next unless ($crosstype = &crosstype($parent1_geno,$parent2_geno,$alleles));
print "@oneline\n" if ($crosstype eq "aabb");

		# Coding CP (cross pollination) genotypes
		for (my $column_num=11;$column_num<scalar(@oneline);$column_num++) {
			# One genotype at $column_num 
			my $temp_genotype = &one2two_letters($alleles, $oneline[$column_num]);
			my $genotype_code = &coding_cp($temp_genotype,$parent1_geno,$parent2_geno,$alleles,$crosstype);
			$oneline[$column_num]=$genotype_code;	
		 }	  
	}
	
	if (!defined($crosstype)) {
		next;
	} else {
 
		#OUTPUT
		for (my $i=0;$i<scalar(@oneline);$i++) {
			my $flag = 0;
			# Check exclude columns and print
			foreach my $j (@exclude_numbers) {
				$flag = 1 if ($i == $j);
			}
			my $printdata = "$oneline[$i]\t";
			&cp_print($crosstype,$printdata,\%fh) if ($flag == 0) 
			
		}
		&cp_print($crosstype,"\n",\%fh)
	}
}

&cp_close(\%fh);


##################################################
#    Subroutines
##################################################

# Subroutine for determination of consensus genotypes
sub consensus_genotype {
	my $geno_consensus;
	my %hash;
#print "@_ in consensus_genotype\n";
	
	foreach my $i (@_) {
		next if ($i eq "NN");
		$hash{$i}++;
	}

	my @hash_keys = keys(%hash);

	# If All samples showed NN,
	if(scalar(@hash_keys) == 0) {
		# consensus is "NN"
		$geno_consensus = "NN";
	} else {
	
		# consensus is only one type.
		if (scalar(@hash_keys) == 1) {
			$geno_consensus = $hash_keys[0];
		
		# consensus is not determined to one type.
		} else {
			$geno_consensus = "multiple";
		}
	}
	return $geno_consensus;
}

# Subroutine for judgement of cross type from the parental genotypes. 
sub crosstype {
	my $parent1_genotype = $_[0];  # two letters are expected.
	my $parent2_genotype = $_[1];  # two letters are expected.
	my $bimorphism = $_[2];
	my $type;
	my ($first_nuc, $second_nuc) = split(/\//,$bimorphism);

	# unknown nucleotides are not allowed.
	if ($parent1_genotype =~ /NN/i or $parent2_genotype =~ /NN/i) {
		$type = "fail";
		return $type;
	};
		
	# check bimorphic nucleotides in parent1 and parent2
	if ($parent1_genotype =~ /[^$first_nuc$second_nuc]/i or $parent2_genotype =~ /[^$first_nuc$second_nuc]/i) {
		$type = "fail";
		return $type;
	};

	# Evaluation of parent1_genotype
	# CASE1 $parent1 is hetero
	if ($parent1_genotype =~ /$first_nuc$second_nuc/i or $parent1_genotype =~ /$second_nuc$first_nuc/i) {
		# CASE 1-1 $parent2 is hetero
		if ($parent2_genotype =~ /$first_nuc$second_nuc/i or $parent2_genotype =~ /$second_nuc$first_nuc/i) {
			$type = "hkhk";
		# CASE 1-2 $parent2 is homo
		} elsif ($parent2_genotype =~ /$first_nuc$first_nuc/i or $parent2_genotype =~ /$second_nuc$second_nuc/i) {
			$type = "lmll";
		};
	# CASE2 $parent1 is homo
	} elsif ($parent1_genotype =~ /$first_nuc$first_nuc/i or $parent1_genotype =~ /$second_nuc$second_nuc/i) {
		# CASE 2-1 $parent2 is hetero
		if ($parent2_genotype =~ /$first_nuc$second_nuc/i or $parent2_genotype =~ /$second_nuc$first_nuc/i) {
			$type ="nnnp";

		# CASE 2-2 $parent2 is homo
		} elsif ($parent2_genotype =~ /$first_nuc$first_nuc/i or $parent2_genotype =~ /$second_nuc$second_nuc/i) {
				
			# CASE 2-2a Genotypes of $parent1 and $parent2 are identical.
			if ($parent1_genotype eq $parent2_genotype) {
				$type = "aaaa";
		
			# CASE 2-2b Genotypes of $parent1 and $parent2 are hom and different.
			} else {
				$type = "aabb";
			}
		}
	}	
	return $type;	
};

sub coding_cp {
	my ($temp_genotype,$parent1_genotype,$parent2_genotype,$alleles,$crosstype) = @_;
	my $genotype_code;
	my ($allele1,$allele2) = split(/\//,$alleles);

	# hk x hk case
	if ($crosstype eq 'hkhk') {
		if ($temp_genotype =~ /$allele1$allele1/i) {
			$genotype_code = "hh";
		} elsif ($temp_genotype =~ /$allele2$allele2/i) {
			$genotype_code = "kk";
		} elsif ($temp_genotype =~ /$allele1$allele2/i or $temp_genotype =~ /$allele2$allele1/i) {
			$genotype_code = "hk";
		} elsif ($temp_genotype =~ /n/i) {
			$genotype_code = "-";
		}
	# lm x ll case
	} elsif ($crosstype eq 'lmll') {
		# for example parent1=CT parent2=TT at C/T site
		if ($parent2_genotype =~ /$allele2$allele2/i) {
			# temp_genotype = CC
			if ($temp_genotype eq "$allele1$allele1") {
				$genotype_code = "-";
			# temp_genotype = TT
			} elsif ($temp_genotype eq "$allele2$allele2") {
				$genotype_code = "ll";
			# temp_genotype = CT
			} elsif ($temp_genotype eq "$allele1$allele2" or $temp_genotype eq "$allele2$allele1") {
				$genotype_code = "lm";
			} elsif ($temp_genotype =~ /n/i) {
				$genotype_code = "-";
			}
		# for example, parent1=CT and parent2=CC at C/T site
		} elsif ($parent2_genotype =~ /$allele1$allele1/i) {
			# temp_genotype = CC
			if ($temp_genotype eq "$allele1$allele1") {
				$genotype_code = "ll"; 
			# temp_genotype = TT
			} elsif ($temp_genotype eq "$allele2$allele2") {
				$genotype_code = "-";
			# temp_genotype = CT
			} elsif ($temp_genotype eq "$allele1$allele2" or $temp_genotype eq "$allele2$allele1") {
				$genotype_code = "lm";
			} elsif ($temp_genotype =~ /n/i) {
				$genotype_code = "-";
			}
		}	
	# nn x np case
	} elsif ($crosstype eq 'nnnp') {
		# For example, parent1=CC and parent2=CT at C/T site
		if ($parent1_genotype =~ /$allele1$allele1/) {
			# temp_genotype = CC
			if ($temp_genotype eq "$allele1$allele1") {
				$genotype_code = "nn";
			# temp_genotype = TT
			} elsif ($temp_genotype eq "$allele2$allele2") {
				$genotype_code = "-";
			# temp_genotyep = CT
			} elsif ($temp_genotype eq "$allele1$allele2" or $temp_genotype eq "$allele2$allele1") {
				$genotype_code = "np";
			} elsif ($temp_genotype =~ /n/i) {
				$genotype_code = "-";
			}
		# For example, parent1=TT and parent2=CT at C/T site
		} elsif ($parent1_genotype =~ /$allele2$allele2/) {
			# temp_genotype = CC
			if ($temp_genotype eq "$allele1$allele1") {
				$genotype_code = "-";
			# temp_genotype = TT
			} elsif ($temp_genotype eq "$allele2$allele2") {
				$genotype_code = "nn";
			} elsif ($temp_genotype eq "$allele1$allele2" or $temp_genotype eq "$allele2$allele1") {
				$genotype_code = "np";
			} elsif ($temp_genotype =~ /n/i) {
				$genotype_code = "-";
			}
		}

	# AA x BB case
	} elsif ($crosstype eq 'aabb') {
		# For example, parent1=CC and parent2=TT at C/T site
		if ($parent1_genotype =~ /$allele1$allele1/) {
			# temp_genotype = CC
			if ($temp_genotype eq "$allele1$allele1") {
				$genotype_code = "A";
			# temp_genotype = TT
			} elsif ($temp_genotype eq "$allele2$allele2") {
				$genotype_code = "B";
			# temp_genotyep = CT
			} elsif ($temp_genotype eq "$allele1$allele2" or $temp_genotype eq "$allele2$allele1") {
				$genotype_code = "H";
			} elsif ($temp_genotype =~ /n/i) {
				$genotype_code = "-";
			}
		
		# For example, parent1=TT and parent2=CC at C/T site
		} elsif ($parent1_genotype =~ /$allele2$allele2/) {
			# temp_genotype = CC
			if ($temp_genotype eq "$allele1$allele1") {
				$genotype_code = "B";
			# temp_genotype = TT
			} elsif ($temp_genotype eq "$allele2$allele2") {
				$genotype_code = "A";
			} elsif ($temp_genotype eq "$allele1$allele2" or $temp_genotype eq "$allele2$allele1") {
				$genotype_code = "H";
			} elsif ($temp_genotype =~ /n/i) {
				$genotype_code = "-";
			}
		}
	} elsif ($crosstype eq 'aaaa') {
		$genotype_code ="A"
	};
	return $genotype_code;
}


sub cp_open {
	my %fh;
	open ($fh{'aabb'},">ABH.txt");
	open ($fh{'hkhk'},">joinmap_HKHK.txt");
	open ($fh{'lmll'},">joinmap_LMLL.txt");
	open ($fh{'nnnp'},">joinmap_NNNP.txt");
	open ($fh{'cp'},">joinmap_CP.txt");
	return %fh;
}

sub cp_close {
	my %fh = %{$_[0]};
	close ($fh{'aabb'});
	close ($fh{'hkhk'});
	close ($fh{'lmll'});
	close ($fh{'nnnp'});
	close ($fh{'cp'});

}

sub cp_print {
	my $crosstype = $_[0];
	my $content = $_[1];
	my %fh = %{$_[2]};

	if ($crosstype =~ "header") {
		print {$fh{'hkhk'}} "$content";
		print {$fh{'lmll'}} "$content";
		print {$fh{'nnnp'}} "$content";
		print {$fh{'cp'}} "$content";
		print {$fh{'aabb'}} "$content";
	};

	if ($crosstype =~ "hkhk") {
		print {$fh{'hkhk'}} "$content";
		print {$fh{'cp'}} "$content";
	};

	if ($crosstype =~ "lmll") {
		print {$fh{'lmll'}} "$content";
		print {$fh{'cp'}} "$content";
	};

	if ($crosstype =~ "nnnp") {
		print {$fh{'nnnp'}} "$content";
		print {$fh{'cp'}} "$content";
	}

	if ($crosstype =~ "aabb") {
		print {$fh{'aabb'}} "$content";
	}
}


sub one2two_letters {
	my ($alleles, $one_or_two_letters) = ($_[0],$_[1]);
	my $converted_two_letters;
	$one_or_two_letters = "N" if ($one_or_two_letters eq "-");
	$one_or_two_letters = "N" if ($one_or_two_letters eq "00");
		
	if (length($one_or_two_letters) == 2) {
	
		$converted_two_letters = $one_or_two_letters;
		$converted_two_letters = "AT" if ($converted_two_letters eq "TA"); #Forced to AT
		$converted_two_letters = "AG" if ($converted_two_letters eq "GA"); #Forced to AG
		$converted_two_letters = "AC" if ($converted_two_letters eq "CA"); #Forced to AC
		$converted_two_letters = "TG" if ($converted_two_letters eq "GT"); #Forced to TG
		$converted_two_letters = "TC" if ($converted_two_letters eq "CT"); #Forced to TC
		$converted_two_letters = "GC" if ($converted_two_letters eq "CG"); #Forced to GC
		
	} elsif (length($one_or_two_letters) == 1) {
		my $one_letter = $one_or_two_letters;
		# A/T sites = W
		if ($alleles eq "A/T" or $alleles eq "T/A") {
			if ($one_letter eq "A") {
				$converted_two_letters = "AA";
			} elsif ($one_letter eq "W") {
				$converted_two_letters = "AT";
			} elsif ($one_letter eq "T") {
				$converted_two_letters = "TT";
			} elsif ($one_letter eq "N") {
				$converted_two_letters = "NN";
			}
		};
	
		# A/G sites = R
		if ($alleles eq "A/G" or $alleles eq "G/A") {
			if ($one_letter eq "A") {
				$converted_two_letters = "AA";
			} elsif ($one_letter eq "R") {
				$converted_two_letters = "AG";
			} elsif ($one_letter eq "G") {
				$converted_two_letters = "GG";
			} elsif ($one_letter eq "N") {
				$converted_two_letters = "NN";
			}
		};
	
		# A/C sites = M
		if ($alleles eq "A/C" or $alleles eq "C/A") {
			if ($one_letter eq "A") {
				$converted_two_letters = "AA";
			} elsif ($one_letter eq "M") {
				$converted_two_letters = "AC";
			} elsif ($one_letter eq "C") {
				$converted_two_letters = "CC";
			} elsif ($one_letter eq "N") {
				$converted_two_letters = "NN";
			}
		};
	
		# T/G sites = K
		if ($alleles eq "T/G" or $alleles eq "G/T") {
			if ($one_letter eq "T") {
				$converted_two_letters = "TT";
			} elsif ($one_letter eq "K") {
				$converted_two_letters = "TG";
			} elsif ($one_letter eq "G") {
				$converted_two_letters = "GG";
			} elsif ($one_letter eq "N") {
				$converted_two_letters = "NN";
			}
		};
	
		#  T/C sites = Y
		if ($alleles eq "T/C" or $alleles eq "C/T") {
			if ($one_letter eq "T") {
				$converted_two_letters = "TT";
			} elsif ($one_letter eq "Y") {
				$converted_two_letters = "TC";
			} elsif ($one_letter eq "C") {
				$converted_two_letters = "CC";
			} elsif ($one_letter eq "N") {
				$converted_two_letters = "NN";
			}
		};
	
		# G/C sites = S
		if ($alleles eq "G/C" or $alleles eq "C/G") {
			if ($one_letter eq "G") {
				$converted_two_letters = "GG";
			} elsif ($one_letter eq "S") {
				$converted_two_letters = "GC";
			} elsif ($one_letter eq "C") {
				$converted_two_letters = "CC";
			} elsif ($one_letter eq "N") {
				$converted_two_letters = "NN";
			}
		};
	} else {
		$converted_two_letters = "NN";
	}
	return $converted_two_letters;
}




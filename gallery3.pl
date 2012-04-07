#!/usr/bin/perl

use XML::Simple;

# how to read metadata?
%initial_configuration = (
	metadata_file => 'metadata.txt', # all other conf will be read from there
	metadata_prefix_comment => '#',
	metadata_prefix_configuration_variable => '$',
	# qr prefix compiles regexp for use as scalar
	metadata_delimiter_configuration_variable => qr/\s+=\s+/,
	metadata_delimiter_csv => qr/\s+/
);

############################ methods

sub z3_trim {
	$x = $_[0];
	$x =~ s/^\s+//; # left trim
	$x =~ s/\s+$//; # right trim
	return $x;
}

sub z3_read_configndata {
	$h = shift;
	%result = ();
	while ( my ($key, $value) = each(%{$h})) {
		$result{conf}{$key} = $value;
    	}

	open (METADATA, '<'.$result{conf}->{metadata_file}) 
		or die 'Cant open metadata file '.$result{conf}{metadata_file}.' for reading!';
    binmode METADATA, ":utf8";
    
	while (<METADATA>) {
		$row = z3_trim $_;
		if ($row eq '') { next; }
		$prefix = substr $row, 0, 1;
		if ($prefix eq $result{'conf'}{metadata_prefix_comment}) {
			next;
		} else { if ($prefix eq $result{'conf'}{metadata_prefix_configuration_variable}) {
			# read configuration variable
			$confrow = substr $row, 1;
			@confitems = split 
				$result{'conf'}{metadata_delimiter_configuration_variable}, 
				$confrow;
			$result{'conf'}{$confitems[0]} = $confitems[1];
		} else {
			# read data row
			@strtokens = split $result{'conf'}{metadata_delimiter_csv}, $row;
			$filename = shift @strtokens; # remove and return 1st element from array
			push @{$result{'data'}}, $filename; # add element to the end of array
			push @{$result{'data'}}, join(' ', @strtokens);
		}}
		#print $row."\n";
	}

	close(METADATA);
	return %result;
}

sub z3_create_tn_fname_body {
	if($_[1]) {
		$tn = $_[0];
	} else {
		@tmp = split(/\./,$_[0]);
		pop(@tmp);
		$tn = join('.',@tmp);
	}
	return $tn;
}

sub z3_html_row_pointer {
	return '&nbsp;<a name="r'.$_[0].'"><a href="#r'.$_[0].'">'.$_[0].'</a></a>';
}

############################ init

%d = z3_read_configndata \%initial_configuration;
# comment next line out if you dont have Data::Dumper
print "\nFinal configuration as seen by Data::Dumper :\n\n"; use Data::Dumper; print Dumper(%d);
@anchors = @{$d{data}};
%janchors = {};
%picflags = {};

# thumbnail's name consists video's fileextension?
$tn_strategy_long = $d{conf}{tn_strategy_long} eq 'yes';

# remove duplicates
if($d{conf}{delete_duplicates} ne 'no' 
	&& length(`which fdupes`)) { system("fdupes -r -d -N ".$d{conf}{vid_dir}); } 
if(!(-e $d{conf}{gallery_dir})) { system("mkdir ".$d{conf}{gallery_dir}); }

opendir(DIR, $d{conf}{vid_dir}) or die "$d{conf}{vid_dir} is unreadable!\n";
@files = sort( grep(/(mpe?g|wmv|avi|f[l4]v|mp4|divx|mov|wbmp)$/i, readdir(DIR) ) );
closedir(DIR);

if($d{conf}{order_by} eq 'name') {
	# order by filename
	sort @files;
} else {
	# order by file modified time 
	@files = sort {(stat($d{conf}{vid_dir}.$a))[9] <=> (stat($d{conf}{vid_dir}.$b))[9]} 
		@files;
}

$filecount = $#files + 1;
$j = 1;
@empty_thumbs = qw();

$descriptions = 0;
if(-e $d{conf}{descriptions_file}) {
    $xml = new XML::Simple;
    $descr_data = $xml->XMLin($d{conf}{descriptions_file});
    $descriptions = $#{$descr_data->{d}};
    if($#anchors < 0) { @anchors = qw(); }
    for($di=0; $di<=$descriptions; $di++) {
        if($descr_data->{d}[$di]->{label} ne '') {
            push @anchors, $descr_data->{d}[$di]->{filename};
            push @anchors, $descr_data->{d}[$di]->{label};
        }
    }
}
$has_movie_index = $#anchors > -1;

############################ real work

open (INDEXFILE, '>'.$d{conf}{index_html});
binmode INDEXFILE, ":utf8";
print INDEXFILE <<EndHTML;
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>$d{conf}{title}</title>
<meta http-equiv="content-type" content="text/html; charset=UTF-8"/>
<link rel="stylesheet" href="gallery.css" type="text/css" />
<style type="text/css">
img {height:$d{conf}{height}px; width:$d{conf}{width}px;}
</style>
EndHTML

if($has_movie_index || $descriptions > 0 ){
print INDEXFILE <<EndHTML;
<script type="text/javascript" src="js/jquery-1.6.1.min.js"></script>
<script type="text/javascript" src="js/overlib/overlib.js"></script>
<script type="text/javascript">

var fpConf = {
   thumbnail_height: $d{conf}{height},
   thumbnail_width: $d{conf}{width}
}

</script>
<script type="text/javascript" src="js/z3_export.js"></script>
<script type="text/javascript" src="js/functions.js"></script>
<script type="text/javascript">

\$(document).ready(function(){

    for(i=0;i<z3picFlags.length;i+=2) {
        id = z3picFlags[i];
        
        if((z3picFlags[i+1]>>1)%2 == 1) { // picture has description
            \$('#a'+id).mouseover(function() {return ol4t(this.id.substr(1));});
            \$('#a'+id).mouseout(function() {return nd();});
            \$('#d'+id).mouseover(function() {return ol4j(this.id.substr(1));});
            \$('#d'+id).mouseout(function() {return nd();});
        }
        
        if((z3picFlags[i+1]>>2)%2 == 1) { // has link back to row from label
            \$('#l'+id).mouseover(function() {return ol4j(this.id.substr(1));});
            \$('#l'+id).mouseout(function() {return nd();});
        }
        
    }

});

</script>
EndHTML
}

print INDEXFILE "</head>\n<body>\n";

if($has_movie_index || $descriptions > 0 ){ 
	print INDEXFILE '<div id="overDiv" style="position:absolute; visibility:hidden; z-index:1000;"></div>'."\n";
}
$descriptions_html = '';
$pic_no = 0;
foreach(@files) {
    $clean_filename = $_;
	$file=$d{conf}{vid_dir}.$_;
	$tn = $d{conf}{gallery_dir}.z3_create_tn_fname_body($_,$tn_strategy_long).'.png';
	if (-e $file) { 
		
		if(!(-e $tn)) {
			system('ffmpeg -y -i '.$file
				.' -vframes 1 -ss '.$d{conf}{snapshot_time}.' -an -vcodec png -f rawvideo -s '
				.$d{conf}{width}.'x'.$d{conf}{height}.' '.$tn);
		}

        if(-s $tn == 0 ) { 
            # if auto cleaning is on & thumbnail is empty delete video & thumbnail
            if($d{conf}{autoclean} ne 'no') {
                system('rm '.$tn);
                system('rm '.$file);
                $filecount --;
                next;
            } else {
                push @empty_thumbs, z3_create_tn_fname_body($_,$tn_strategy_long).'.png';
                # 1 - has no thumbnail
                if(!$picflags{$pic_no}) {
                    $picflags{$pic_no} = 1;
                } else {
                    $picflags{$pic_no} = $picflags{$pic_no} | 1;
                }
            }
        }
        
		$anchorrow = (1+((($j-1) - (($j-1)%$d{conf}{jmax})) / $d{conf}{jmax}));
		
        for($ai=0; $ai<$#anchors; $ai+=2) {
             if($anchors[$ai] eq $_){
                if(!$janchors{$anchors[$ai+1]}) {
                    $janchors{$anchors[$ai+1]}[0] = $anchorrow;
                } else {
                    push @{$janchors{$anchors[$ai+1]}}, $anchorrow;
                }
                push @{$janchors{$anchors[$ai+1]}}, $pic_no;
            }
        }
        
        $link_attrs = '';
        if($descriptions > 0) {
            $txt = '';
            for($di=0; $di<=$descriptions; $di++) {
                if($descr_data->{d}[$di]->{filename} eq $clean_filename) {
                    $txt = $descr_data->{d}[$di]->{txt};
                    last;
                }
            }
            if($txt ne '') {
                $descriptions_html .= '<li><a'
                    .' id="d'
                    .$pic_no
                    .'"'
                    .' href="#r'
                    .$anchorrow
                    .'"'
                    #.' onmouseover="return ol4j('.$pic_no.');" '
                    #.' onmouseout="return nd();"'
                    .'>'
                    .$txt
                    .'</a></li>'."\n";
                # 2 - has description
                if(!$picflags{$pic_no}) {
                    $picflags{$pic_no} = 2;
                } else {
                    $picflags{$pic_no} = $picflags{$pic_no} | 2;
                }
            }
        }
        
		@size = split /\s+/, `du -h $file`;
		print INDEXFILE '<a id="a'
                    .$pic_no
                    .'" href="'.$file.'" title="'
			.$size[0]
			.'"'.$link_attrs.'><img src="'.$tn.'"/></a>'."\n";
		if($j % $d{conf}{jmax} == 0) { # end of row
			print INDEXFILE z3_html_row_pointer($j / $d{conf}{jmax})."\n";
			if($j == $d{conf}{jmax}) { # end of 1st row
				print INDEXFILE '&nbsp;<a href="#end">&gt;|</a>';
			}
			print INDEXFILE "<br />\n";
		}

	} else {
		system('rm '.$tn);
	}
	$j++;
    $pic_no++;
}

$anchorshtmlrendered = '';
if($#anchorshtml > 0) {
	$anchorshtmlrendered = '<ol>'.join('',@anchorshtml).'</ol>';
}

# delete orphaned thumbnails
if($tn_strategy_long) {
opendir(TNDIR, $d{conf}{gallery_dir}) or die "$d{conf}{gallery_dir} is unreadable!\n";
@tnfiles = grep(/png$/i, readdir(TNDIR) );
foreach(@tnfiles) {
	if (!(-e $d{conf}{vid_dir}.z3_create_tn_fname_body($_,0))) {
		system('rm '.$d{conf}{gallery_dir}.$_);
	}
}
}

if($filecount % $d{conf}{jmax} != 0) {
	print INDEXFILE z3_html_row_pointer(($filecount 
		- ($filecount % $d{conf}{jmax}) + $d{conf}{jmax}) / $d{conf}{jmax})
		.'<br />';
}

@t = localtime();
print INDEXFILE '<a name="end"><a href="#r1">'.$d{conf}{title}.': '.$filecount.' files, '
	.sprintf("%d-%02d-%02d %02d:%02d:%02d",$t[5]+1900,$t[4]+1,$t[3],$t[2],$t[1],$t[0])
	.'</a></a>, '
	.'<a href="'.$d{conf}{vid_dir}.'" target="_blank">'
	.`du -h -s $d{conf}{vid_dir}`
	.'</a>. <a href="'.$d{conf}{flashplayer_html}.'">Flashplayer</a>, <a href="'.$d{conf}{flashplayer_html}.'?p=w">WindowsMediaPlayer</a>';

print INDEXFILE "<ol>\n";
foreach $key (sort (keys(%janchors))) {
    if($janchors{$key}) {
        @aa = @{$janchors{$key}};
        print INDEXFILE '<li><a'
            .' id="l'.$janchors{$key}[1].'"'
            .' href="#r'
            .$janchors{$key}[0]
            .'"'
            #.' onmouseover="return ol4j('.$janchors{$key}[1].');" '
            #.' onmouseout="return nd();"'
            .'>'
            .$key
            .'</a>';
            # 4 - has link back to row from label
            if(!$picflags{$janchors{$key}[1]}) {
                $picflags{$janchors{$key}[1]} = 4;
            } else {
                $picflags{$janchors{$key}[1]} = $picflags{$janchors{$key}[1]} | 4;
            }
        for($aai=2; $aai<$#aa; $aai+=2) {
            print INDEXFILE ",\n "
                .'<a'
                .' id="l'.$janchors{$key}[$aai+1].'"'
                .' href="#r'
                .$janchors{$key}[$aai]
                .'"'
                #.' onmouseover="return ol4j('.$janchors{$key}[$aai+1].');" '
                #.' onmouseout="return nd();"'
                .'>'
                .(($aai/2)+1)
                .'</a>';
                # 4 - has link back to row from label
                if(!$picflags{$janchors{$key}[$aai+1]}) {
                    $picflags{$janchors{$key}[$aai+1]} = 4;
                } else {
                    $picflags{$janchors{$key}[$aai+1]} = $picflags{$janchors{$key}[$aai+1]} | 4;
                }
            }
        print INDEXFILE "</li>\n";
    }
}
print INDEXFILE "</ol>\n";

if($descriptions_html ne '') {

print INDEXFILE '<a name="descriptions"><a href="#descriptions" onClick="$(\'#descr_list\').toggle(); return true;">Descriptions</a></a><div id="descr_list"><ol>'
    .$descriptions_html.'</ol></div>';

}

print INDEXFILE <<EndHTML;
</body>
</html>
EndHTML

close (INDEXFILE);

open (JSFILE, '>'.$d{conf}{z3_export_js});
binmode JSFILE, ":utf8";
print JSFILE "var z3Conf = {\n";
for (keys %{$d{conf}}) {
        if($d{conf}{$_} =~ /^\d+$/) {
            print JSFILE $_.":".$d{conf}{$_}.",\n";
        } else {
            $str = $d{conf}{$_};
            $str =~ s/'/\\'/g;
            print JSFILE $_.":'".$str."',\n";
        } 
}
print JSFILE "}";

print JSFILE "\n\nvar z3emptyThumbsS = '";
print JSFILE join(",", @empty_thumbs);
print JSFILE "';";

print JSFILE "\n\nvar z3picFlags = new Array(";
$i = 0;
for (keys %picflags) {
    if($picflags{$_}=~/^\d+$/) {
        if($i > 0) { print JSFILE ","; }
        print JSFILE "\n".$_.",".$picflags{$_};
        $i++;
    }
}
print JSFILE ");";

close (JSFILE);

# useful only if $d{conf}{webbrowser} is installed
if(length(`which $d{conf}{webbrowser}`)) { 
	system($d{conf}{webbrowser}.' '.$d{conf}{index_html});
}

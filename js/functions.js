function querySt(ji) {
    hu = window.location.search.substring(1);
    gy = hu.split("&");
    for (i=0;i<gy.length;i++) {
        ft = gy[i].split("=");
        if (ft[0] == ji) {return ft[1];}
    }
    return false;
}

function preparePlayerURL() {
 return fpConf.playerPage
        + '?h='
        + GetRequest.h 
        + '&w='
        + GetRequest.w 
        + '&m='
        + GetRequest.m
        + '&l='
        + GetRequest.l
        + '&p='
        + GetRequest.p
        + '&f=';
}

function isEmptyThumbnail(filename) {
    return z3emptyThumbsS.indexOf(filename) != -1;
}

function ol4i (video, thumbnail) {
    if(isEmptyThumbnail(thumbnail)) {return true;}
    return overlib('<a href=\''
        +video
        +'\'><img src=\''
        +thumbnail
        +'\' width=\'' + fpConf.thumbnail_width
        +'\' height=\'' + fpConf.thumbnail_height
        +'\ /></a>',
        STICKY, MOUSEOFF, VAUTO,
        WIDTH, 2 + fpConf.thumbnail_width,
        HEIGHT, 2 + fpConf.thumbnail_height,
        FGCOLOR, '#000000',
        BGCOLOR, '#FFFFFF');
}

function ol4j(link_no) {
    imga = $('#a'+link_no).html().split(" ");
    imgs = imga[1].substr(5);
    return ol4i($('#a'+link_no).attr('href'), imgs.substr(0,imgs.length-2));
}

function ol4t (txt_no) {
    return overlib($('#d'+txt_no).html(),
        STICKY, MOUSEOFF, VAUTO,
        CELLPAD, 10,
        TEXTCOLOR, '#FFFFFF',
        FGCOLOR, '#000000',
        BGCOLOR, '#FFFFFF');
}

function ol4iHTML (videofilename) {
    thumbnail = fpConf.thumbnail_directory
            + videofilename
            + fpConf.thumbnail_extension;
    if(isEmptyThumbnail(thumbnail)) {return " onmouseout=\"return nd();\" ";}
    if(fpConf.thumbnail_directory != '') {
        return " onmouseover=\"return ol4i('"
            + fpConf.dirVideo
            + videofilename
            + "','"
            + thumbnail
            + "');\" onmouseout=\"return nd();\" ";
    } else {
        return '';
    }
}


function dirtyForm(inputfield) {
    inputfield.form.elements['c'].value = 1; //form is changed
    return true;
}

function menuEtc(videofile, dataURL, uniqVids) {

    vidUniqId = -1;
    lst = '';
    if(uniqVids.length < 1) {
        lst = '<hr/>Can\'t load anything from <a href="' 
            + dataURL
            + '" target="_blank">' 
            + dataURL
            + '</a> using regexp <a href="js/fpconf.js" target="_blank">'
            + fpConf.vidRegexp
            + '</a>';
    } else {
    
        for(i=0; i<uniqVids.length;i++) {
            if(videofile == uniqVids[i]) {
                lst += '<li><strong>' 
                    + uniqVids[i]
                    + '</strong></li>';
                vidUniqId = i;
            } else {
                lst += '<li><a href="' 
                    + preparePlayerURL() + uniqVids[i]
                    + '"'
                    + ol4iHTML(uniqVids[i])
                    + '>'
                    + uniqVids[i]
                    + '</a></li>';
            }
        }
        
        lst = '<ol>' + lst + '</ol>';
    }
    
    return {
        menuHTML: lst,
        vidUniqId: vidUniqId
    }
}


function navigation(videofile, vidUniqId, uniqVids) {

        nowPlaying = '';
        var videofilename = '';
        if(videofile != '') {

            nowPlaying = 'Now playing:';

            videofilename = uniqVids[ vidUniqId == 0
                        ? uniqVids.length -1
                        : vidUniqId -1];
            if(uniqVids.length > 1) {
                nowPlaying += ' <a href="';
                nowPlaying += preparePlayerURL() + videofilename;
                nowPlaying += '"';
                nowPlaying += ol4iHTML(videofilename);
                nowPlaying += '>&lt;&lt;</a>';
            }
            
            nowPlaying += ' <a href="'
                    + preparePlayerURL()
                    //+ fpConf.dirVideo
                    + videofile
                    + '">'
                    + videofile
                    + '</a>';

            videofilename = uniqVids[ vidUniqId > uniqVids.length -2
                        ? 0
                        : vidUniqId +1];
            if(uniqVids.length > 1) {
                nowPlaying += ' <a href="';
                nowPlaying += preparePlayerURL() + videofilename;
                nowPlaying += '"';
                nowPlaying += ol4iHTML(videofilename);
                nowPlaying += ' id="nextclip">&gt;&gt;</a>';
            }

        }
        
    return {
        nowPlaying: nowPlaying,
        nextVideo: videofilename
    }
}

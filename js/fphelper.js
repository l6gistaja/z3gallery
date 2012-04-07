// INIT // INIT // INIT // INIT // INIT // INIT // INIT // INIT // INIT // INIT

// if z3_export.js exists, overwrite fpConf with z3Conf values
if(z3Conf.vid_dir !== undefined) {
   fpConf.dirVideo = z3Conf.vid_dir; //subdirectory which contains videos
   fpConf.playerPage = z3Conf.flashplayer_html; //HTML page which plays videos
   fpConf.staticListing = z3Conf.index_html;  //data file from which vidRegexp tries to get videofiles
   fpConf.thumbnail_directory = z3Conf.gallery_dir; // thumbnail directory; if '' then thumbnail arent available
   fpConf.thumbnail_height = z3Conf.height;
   fpConf.thumbnail_width = z3Conf.width;
}

// HTTP GET variables
tmp = parseInt(querySt("h"));
if(!isNaN(tmp) && tmp>0) { GetRequest.h = tmp; }

tmp = parseInt(querySt("w"));
if(!isNaN(tmp) && tmp>0) { GetRequest.w = tmp; }

tmp = parseFloat(querySt("m"));
if(!isNaN(tmp) && tmp>0) { GetRequest.m = tmp; }

tmp = querySt("f");
if(tmp !== false) { GetRequest.f = tmp; }

tmp = querySt("l");
GetRequest.l = (tmp !== false && tmp == '1') ? 1 : 0;

tmp = querySt("p");
GetRequest.p = (tmp == false || (tmp != 'f' && tmp != 'w')) ? 'f' : tmp;

var descriptions = {};

// OnLoad inits
// Use jQuery via jQuery(...)
var $jq = jQuery.noConflict();

$jq(document).ready(function(){

    if(GetRequest.p == 'w') {
        $jq('#li_loop_playlist').hide();
        $jq('#li_enable_localdirs').hide();
    }
    
    if(z3Conf.descriptions_file !== undefined) {

        $jq.ajax({
            type: "GET",
            url: z3Conf.descriptions_file,
            dataType: "xml",
            success: function(xml) {
                $jq(xml).find('d').each(function(){
                    var o = new Object();
                    o.title = $jq(this).find('title').text();
                    o.label = $jq(this).find('label').text();
                    o.txt = $jq(this).find('txt').text();
                    var fn = $jq(this).attr('filename');
                    descriptions[fn] = o;
                });
            }
        });
        
    }

    
    function playnext() {
    
        if(document.forms['dimensions'].elements['c'].value == '1') {
            document.forms['dimensions'].elements['f'].value = nextVideo;
            document.forms['dimensions'].submit();
        } else {
            var nextMenu = menuEtc(nextVideo, dataURL, uniqVids);
            $jq("#videos").empty().html(nextMenu.menuHTML);
            var nextNav = navigation(nextVideo, nextMenu.vidUniqId, uniqVids);
            $jq("#playerbar").html(nextNav.nowPlaying);
            player.play(fpConf.dirVideo + nextVideo);
            nextVideo = nextNav.nextVideo;
        }
        
    }
    
    for (var prop in GetRequest) {
        if(prop == 'l') {
            document.forms['dimensions'].elements[prop].checked = (GetRequest[prop] == 1);
        } else {
            document.forms['dimensions'].elements[prop].value = GetRequest[prop];
        }
    }
    document.forms['dimensions'].action = fpConf.playerPage;

    lst = ''; 

    dataURL = location.href.match(/^http(s)?:\/\//)
        ? fpConf.dirVideo
        : fpConf.staticListing;

    var stringData = $jq.ajax({
                    url: dataURL,
                    async: false
                 }).responseText;
    var videoArray = stringData.match(GetRequest.p == 'f' ? fpConf.vidRegexp : fpConf.windowsMediaVidRegexp);
    var uniqVids = new Array();
    if(videoArray != null) {

        // make video names array unique
        for(i=0; i<videoArray.length;i++) {
            cleanVideoURL = videoArray[i];
            vidIsUniq = true;
            for(j=0;j<uniqVids.length;j++) { 
                if(uniqVids[j] == cleanVideoURL) {
                    vidIsUniq = false;
                    continue; 
                }
             } 
            if(!vidIsUniq){ continue; }
            uniqVids[uniqVids.length] = cleanVideoURL;
        }
        
        // create menu from filenames
        var menu = menuEtc(GetRequest.f, dataURL, uniqVids);
        
        // create navigation bar
        var nav = navigation(GetRequest.f, menu.vidUniqId, uniqVids);
        nextVideo = nav.nextVideo;

    }

    $jq("#playerbar").html(nav.nowPlaying);
    $jq("#videos").html(menu.menuHTML);
    
    
    if(GetRequest.f != '') {
        // setup player normally
        var player = $f("player", fpConf.dirPlayer + "flowplayer-3.2.7.swf", {
        
            // clip properties common to all playlist entries
            clip: {
                onFinish: function(clip) {
                    if(document.forms['dimensions'].elements['l'].checked) { playnext(); }
                }
            }
        });
    }

});